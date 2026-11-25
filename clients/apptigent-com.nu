# Auto-generated client for PowerTools Developer v2021.1.01
# Source: https://api.apis.guru/v2/specs/apptigent.com/2021.1.01/openapi.json
# Auth: --token flag or $env.POWERTOOLS_DEVELOPER_TOKEN

const CLIENT = {
  base_url: "https://connect.apptigent.com/api/utilities"
  token_env_var: "POWERTOOLS_DEVELOPER_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: x-ibm-client-id, in: header, header_name: X-IBM-Client-Id, prefix: ""}
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

def base-url-completer [] { ["https://connect.apptigent.com/api/utilities"] }
def auth-scheme-completer [] { ["x-ibm-client-id"] }

# Completers for enum parameters
def type-completer [] { ["Maximum" "Minimum"] }
def type-completer-1 [] { ["Decimal" "Integer"] }
def ignorecase-completer [] { ["false" "true"] }
def trim-completer [] { ["false" "true"] }
def lower-completer [] { ["false" "true"] }
def source-completer [] { ["Arcminute" "Arcsecond" "Centiradian" "Deciradian" "Degree" "Gradian" "Microdegree" "Microradian" "Millidegree" "Milliradian" "Nanodegree" "Nanoradian" "Radian" "Revolution"] }
def target-completer [] { ["Arcminute" "Arcsecond" "Centiradian" "Deciradian" "Degree" "Gradian" "Microdegree" "Microradian" "Millidegree" "Milliradian" "Nanodegree" "Nanoradian" "Radian" "Revolution"] }
def source-completer-1 [] { ["Acre" "Hectare" "SquareCentimeter" "SquareDecimeter" "SquareFoot" "SquareInch" "SquareKilometer" "SquareMeter" "SquareMicrometer" "SquareMile" "SquareMillimeter" "SquareYard"] }
def target-completer-1 [] { ["Acre" "Hectare" "SquareCentimeter" "SquareDecimeter" "SquareFoot" "SquareInch" "SquareKilometer" "SquareMeter" "SquareMicrometer" "SquareMile" "SquareMillimeter" "SquareYard"] }
def alphacase-completer [] { ["Lower" "Title" "Upper"] }
def source-completer-2 [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RUB" "SEK" "SGD" "THB" "TRY" "USD" "ZAR"] }
def target-completer-2 [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RUB" "SEK" "SGD" "THB" "TRY" "USD" "ZAR"] }
def source-completer-3 [] { ["Centimeter" "Decimeter" "Fathom" "Foot" "Hectometer" "Inch" "Kilometer" "LightYear" "Meter" "Micrometer" "Mile" "Millimeter" "Nanometer" "NauticalMile" "Yard"] }
def target-completer-3 [] { ["Centimeter" "Decimeter" "Fathom" "Foot" "Hectometer" "Inch" "Kilometer" "LightYear" "Meter" "Micrometer" "Mile" "Millimeter" "Nanometer" "NauticalMile" "Yard"] }
def source-completer-4 [] { ["Day" "Hour" "Microsecond" "Millisecond" "Minute" "Month" "Nanosecond" "Second" "Week" "Year"] }
def target-completer-4 [] { ["Day" "Hour" "Microsecond" "Millisecond" "Minute" "Month" "Nanosecond" "Second" "Week" "Year"] }
def source-completer-5 [] { ["BritishThermalUnit" "Calorie" "ElectronVolt" "FootPound" "GigawattHour" "Joule" "Kilocalorie" "Kilojoule" "KilowattHour" "Megajoule" "MegawattHour" "TerawattHour" "Therm (EU)" "Therm (UK)" "Therm (US)" "WattHour"] }
def target-completer-5 [] { ["BritishThermalUnit" "Calorie" "ElectronVolt" "FootPound" "GigawattHour" "Joule" "Kilocalorie" "Kilojoule" "KilowattHour" "Megajoule" "MegawattHour" "TerawattHour" "Therm (EU)" "Therm (UK)" "Therm (US)" "WattHour"] }
def format-completer [] { ["BMP" "GIF" "JPG" "PNG" "TIF"] }
def accept-completer [] { ["image/bmp" "image/gif" "image/jpeg" "image/png"] }
def source-completer-6 [] { ["BritishThermalUnitPerHour" "Decawatt" "Deciwatt" "ElectricalHorsepower" "Femtowatt" "Gigawatt" "HydraulicHorsepower" "Kilowatt" "MechanicalHorsepower" "Megawatt" "Microwatt" "Milliwatt" "Nanowatt" "Petawatt" "Picowatt" "Terawatt" "Watt"] }
def target-completer-6 [] { ["BritishThermalUnitPerHour" "Decawatt" "Deciwatt" "ElectricalHorsepower" "Femtowatt" "Gigawatt" "HydraulicHorsepower" "Kilowatt" "MechanicalHorsepower" "Megawatt" "Microwatt" "Milliwatt" "Nanowatt" "Petawatt" "Picowatt" "Terawatt" "Watt"] }
def source-completer-7 [] { ["CentimeterPerHour" "CentimeterPerMinute" "CentimeterPerSecond" "DecimeterPerMinute" "DecimeterPerSecond" "FootPerHour" "FootPerMinute" "FootPerSecond" "InchPerHour" "InchPerMinute" "InchPerSecond" "KilometerPerHour" "KilometerPerMinute" "KilometerPerSecond" "Knot" "MeterPerHour" "MeterPerMinute" "MeterPerSecond" "MicrometerPerMinute" "MicrometerPerSecond" "MilePerHour" "MillimeterPerHour" "MillimeterPerMinute" "MillimeterPerSecond" "NanometerPerMinute" "NanometerPerSecond" "YardPerHour" "YardPerMinute" "YardPerSecond"] }
def target-completer-7 [] { ["CentimeterPerHour" "CentimeterPerMinute" "CentimeterPerSecond" "DecimeterPerMinute" "DecimeterPerSecond" "FootPerHour" "FootPerMinute" "FootPerSecond" "InchPerHour" "InchPerMinute" "InchPerSecond" "KilometerPerHour" "KilometerPerMinute" "KilometerPerSecond" "Knot" "MeterPerHour" "MeterPerMinute" "MeterPerSecond" "MicrometerPerMinute" "MicrometerPerSecond" "MilePerHour" "MillimeterPerHour" "MillimeterPerMinute" "MillimeterPerSecond" "NanometerPerMinute" "NanometerPerSecond" "YardPerHour" "YardPerMinute" "YardPerSecond"] }
def source-completer-8 [] { ["Celsius" "Fahrenheit" "Kelvin" "Newton"] }
def target-completer-8 [] { ["Celsius" "Fahrenheit" "Kelvin" "Newton"] }
def source-completer-9 [] { ["Centiliter" "CubicCentimeter" "CubicDecimeter" "CubicFoot" "CubicHectometer" "CubicInch" "CubicKilometer" "CubicMeter" "CubicMillimeter" "CubicYard" "Cup" "Deciliter" "Gallon" "ImperialBeerBarrel" "ImperialGallon" "ImperialOunce" "ImperialPint" "Kiloliter" "Liter" "Microliter" "Milliliter" "Ounce" "Pint" "Quart" "Tablespoon" "Teaspoon"] }
def target-completer-9 [] { ["Centiliter" "CubicCentimeter" "CubicDecimeter" "CubicFoot" "CubicHectometer" "CubicInch" "CubicKilometer" "CubicMeter" "CubicMillimeter" "CubicYard" "Cup" "Deciliter" "Gallon" "ImperialBeerBarrel" "ImperialGallon" "ImperialOunce" "ImperialPint" "Kiloliter" "Liter" "Microliter" "Milliliter" "Ounce" "Pint" "Quart" "Tablespoon" "Teaspoon"] }
def source-completer-10 [] { ["Centigram" "Decagram" "Decigram" "Earth Mass" "Grain" "Gram" "Hectogram" "Kilogram" "Long Hundredweight" "Long Ton" "Megaton" "Microgram" "Milligram" "Nanogram" "Ounce" "Pound" "Short Hundredweight" "Short Ton" "Slug" "Solar Mass" "Stone" "Ton"] }
def target-completer-10 [] { ["Centigram" "Decagram" "Decigram" "Grain" "Gram" "Hectogram" "Kilogram" "Microgram" "Milligram" "Nanogram" "Ounce" "Pound" "Stone" "Ton"] }
def position-completer [] { ["BottomCenter" "BottomLeft" "BottomRight" "MiddleCenter" "MiddleLeft" "MiddleRight" "TopCenter" "TopLeft" "TopRight"] }
def culture-completer [] { ["af-ZA" "ar-AE" "ar-BH" "ar-DZ" "ar-EG" "ar-IQ" "ar-JO" "ar-KW" "ar-LB" "ar-LY" "ar-MA" "ar-OM" "ar-QA" "ar-SA" "ar-SY" "ar-TN" "ar-YE" "az-AZ" "be-BY" "bg-BG" "bs-BA" "ca-ES" "cs-CZ" "cy-GB" "da-DK" "de-AT" "de-CH" "de-DE" "de-LI" "de-LU" "el-GR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-GB" "en-IE" "en-JM" "en-NZ" "en-PH" "en-TT" "en-US" "en-ZA" "en-ZW" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-IR" "fi-FI" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-MC" "gl-ES" "gu-IN" "he-IL" "hi-IN" "hr-BA" "hr-HR" "hu-HU" "hy-AM" "id-ID" "is-IS" "it-CH" "it-IT" "ja-JP" "ka-GE" "kk-KZ" "kn-IN" "ko-KR" "ky-KG" "lt-LT" "lv-LV" "mi-NZ" "mn-MN" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "nl-BE" "nl-NL" "nn-NO" "ns-ZA" "pa-IN" "pl-PL" "ps-AR" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sa-IN" "sk-SK" "sl-SI" "sq-AL" "sr-BA" "sr-SP" "sv-FI" "sv-SE" "sw-KE" "ta-IN" "te-IN" "th-TH" "tl-PH" "tn-ZA" "tr-TR" "uk-UA" "ur-PK" "uz-UZ" "vi-VN" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }
def match-completer [] { ["All" "Any" "None"] }
def orientation-completer [] { ["Horizontal" "Vertical"] }
def uppercase-completer [] { ["false" "true"] }
def algorithm-completer [] { ["MD5" "SHA1" "SHA256" "SHA384" "SHA512"] }
def payload-completer [] { ["Bitcoin Payment (address|amount|label|message)" "Bookmark (url|title)" "Calendar Event (subject|description|location|start|end|allDayEvent['true' or 'false']|format ['universal' or 'iCal'])" "Geolocation (latitude|longitude)" "Mail (recipient|subject|message)" "Phone Number (string)" "Plain Text (string)" "SMS (number|message)" "URL (string)" "WiFi (ssid|password|authenticationMode ['WEP', 'WPA' or 'WPA2'])"] }
def symbol-completer [] { ["CDAXX.INDX (DAX Composite Index [Germany])" "DJA.INDX (Dow Jones Composite Average)" "DJI.INDX (Dow Jones Industrial Average)" "DJT.INDX (Dow Jones Transportation)" "DJUS.INDX (Dow Jones US)" "DXY.INDX (US Dollar Index)" "ES.INDX (S&P 500 Futures)" "FTSE.INDX (FTSE 100 Index [UK])" "GDAXI.INDX (DAX Index [Germany])" "GDOW.INDX (Global Dow USD)" "GPTSE.INDX (S&P TSX Composite Index [Canada])" "GSPC.INDX (S&P 500)" "HSCE.INDX (Hang Seng China Enterprise (CEI))" "HSI.INDX (Hang Seng Index [Hong Kong])" "IXIC.INDX (NASDAQ Composite)" "MID.INDX (S&P Midcap 400)" "N100.INDX (EuroNext 100)" "N225.INDX (Nikkei 225 Index)" "NDX.INDX (NASDAQ 100)" "NY.INDX (NYSE US 100 Index)" "NYA.INDX (NYSE Composite)" "RTSI.INDX (RTSI Index [Russia])" "SSEC.INDX (Shanghai Composite)" "SSMI.INDX (Swiss Market Index)"] }
def ignore-case-completer [] { ["false" "true"] }
def algorithm-completer-1 [] { ["Bicubic (default)" "Bilinear" "Cubic (Box)" "Cubic (Catmull-Rom)" "Cubic (Hermite)" "Cubic (Spline)" "Nearest Neighbor" "Robidoux" "Robidoux Sharp" "Sinc (Lanczos2)" "Sinc (Lanczos3)" "Sinc (Lanczos5)" "Sinc (Lanczos8)"] }
def units-completer [] { ["Percent" "Pixels"] }
def order-completer [] { ["Ascending" "Descending"] }
def language-completer [] { ["Arabic (Bahrain)" "Arabic (Egypt)" "Arabic (Iraq)" "Arabic (Jordan)" "Arabic (Kuwait)" "Arabic (Lebanon)" "Arabic (Oman)" "Arabic (Qatar)" "Arabic (Saudi Arabia)" "Arabic (Syria)" "Arabic (United Arab Emirates)" "Bulgarian (Bulgaria)" "Catalan (Spain)" "Chinese (Cantonese, Traditional)" "Chinese (Mandarin, Simplified)" "Chinese (Taiwanese Mandarin)" "Croatian (Croatia)" "Czech (Czech Republic)" "Danish (Denmark)" "Dutch (Netherlands)" "English (Australia)" "English (Canada)" "English (Hong Kong)" "English (India)" "English (Ireland)" "English (New Zealand)" "English (Philippines)" "English (Singapore)" "English (South Africa)" "English (United Kingdom)" "English (United States)" "Estonian(Estonia)" "Finnish (Finland)" "French (Canada)" "French (France)" "German (Germany)" "Greek (Greece)" "Gujarati (Indian)" "Hindi (India)" "Hungarian (Hungary)" "Irish(Ireland)" "Italian (Italy)" "Japanese (Japan)" "Korean (Korea)" "Latvian (Latvia)" "Lithuanian (Lithuania)" "Maltese(Malta)" "Marathi (India)" "Norwegian (Norway)" "Polish (Poland)" "Portuguese (Brazil)" "Portuguese (Portugal)" "Romanian (Romania)" "Russian (Russia)" "Slovak (Slovakia)" "Slovenian (Slovenia)" "Spanish (Argentina)" "Spanish (Bolivia)" "Spanish (Chile)" "Spanish (Colombia)" "Spanish (Costa Rica)" "Spanish (Cuba)" "Spanish (Dominican Republic)" "Spanish (Ecuador)" "Spanish (El Salvador)" "Spanish (Guatemala)" "Spanish (Honduras)" "Spanish (Mexico)" "Spanish (Nicaragua)" "Spanish (Panama)" "Spanish (Paraguay)" "Spanish (Peru)" "Spanish (Puerto Rico)" "Spanish (Spain)" "Spanish (USA)" "Spanish (Uruguay)" "Spanish (Venezuela)" "Swedish (Sweden)" "Tamil (India)" "Telugu (India)" "Thai (Thailand)" "Turkish (Turkey)"] }
def exchange-completer [] { ["BMEX (Bolsas y Mercados Españoles)" "MISX (Moscow Stock Exchange)" "XASE (American Stock Exchange)" "XASX (Australia Stock Exchange)" "XBKK (Stock Exchange of Thailand)" "XBRU (Euronext Brussels)" "XCNQ (Candadian Securities Exchange)" "XCSE (Copenhagen Stock Exchange)" "XDFM (Dubai Financial Market)" "XFKA (Fukuoka Stock Exchange)" "XFRA (Deutsche Borse)" "XHKG (Hong Kong Stock Exchange)" "XJSE (Johannesburg Stock Exchange)" "XLIS (Euronext Lisbon)" "XLON (London Stock Exchange)" "XMEX (Mexican Stock Exchange)" "XNAS (NASDAQ Stock Exchange)" "XNGO (Nagoya Stock Exchange)" "XNSE (National Stock Exchange India)" "XNYS (New York Stock Exchange)" "XNZE (New Zealand Stock Exchange)" "XPAR (Euronext Paris)" "XSAP (Sapporo Stock Exchange)" "XSES (Singapore Stock Exchange)" "XSHG (Shanghai Stock Exchange)" "XSTO (Stockholm Stock Exchange)" "XSWX (SIX Swiss Exchange)" "XTAE (Tel Aviv Stock Exchange)" "XTSE (Toronto Stock Exchange)"] }
def extension-completer [] { ["CSS" "CSV" "HTML" "JS" "JSON" "TXT" "XML"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/css" "text/csv" "text/html" "text/javascript" "text/plain"] }
def type-completer-2 [] { ["PlainText" "SSML"] }
def voice-completer [] { ["ar-EG, Hoda (Female)" "ar-SA, Naayf (Male)" "bg-BG, Ivan (Male)" "ca-ES, Herena (Female)" "cs-CZ, Jakub (Male)" "da-DK, Helle (Female)" "de-AT, Michael (Male)" "de-CH, Karsten (Male)" "de-DE, Hedda (Female)" "de-DE, Stefan (Male)" "el-GR, Stefanos (Male)" "en-AU, Catherine (Female)" "en-AU, Hayley (Female)" "en-CA, Heather (Female)" "en-CA, Linda (Female)" "en-GB, George (Male)" "en-GB, Hazel (Female)" "en-GB, Susan (Female)" "en-IE, Sean (Male)" "en-IN, Heera (Female)" "en-IN, Priya (Female)" "en-IN, Ravi (Male)" "en-US, Aria (Female)" "en-US, Benjamin (Male)" "en-US, Guy (Male)" "en-US, Zira (Female)" "es-ES, Helena (Female)" "es-ES, Laura (Female)" "es-ES, Pablo (Male)" "es-MX, Hilda (Female)" "es-MX, Raul (Male)" "fi-FI, Heidi (Female)" "fr-CA, Caroline (Female)" "fr-CA, Harmonie (Female)" "fr-CH, Guillaume (Male)" "fr-FR, Hortense (Female)" "fr-FR, Julie (Female)" "fr-FR, Paul (Male)" "he-IL, Asaf (Male)" "hi-IN, Hemant (Male)" "hi-IN, Kalpana (Female)" "hr-HR, Matej (Male)" "hu-HU, Szabolcs (Male)" "id-ID, Andika (Male)" "it-IT, Cosimo (Male)" "it-IT, Lucia (Female)" "ja-JP, Ayumi (Female)" "ja-JP, Haruka (Female)" "ja-JP, Ichiro (Male)" "ko-KR, Heami (Female)" "ms-MY, Rizwan (Male)" "nb-NO, Hulda (Female)" "nl-NL, Hanna (Female)" "pl-PL, Paulina (Female)" "pt-BR, Daniel (Male)" "pt-BR, Heloisa (Female)" "pt-PT, Helia (Female)" "ro-RO, Andrei (Male)" "ru-RU, Ekaterina (Female)" "ru-RU, Irina (Female)" "ru-RU, Pavel (Male)" "sk-SK, Filip (Male)" "sl-SI, Lado (Male)" "sv-SE, Hedvig (Female)" "ta-IN, Valluvar (Male)" "te-IN, Chitra (Female)" "th-TH, Pattara (Male)" "tr-TR, Seda (Female)" "vi-VN, An (Male)" "zh-CN, Huihui (Female)" "zh-CN, Kangkang (Male)" "zh-CN, Yaoyao (Female)" "zh-HK, Danny (Male)" "zh-HK, Tracy (Female)" "zh-TW, HanHan (Female)" "zh-TW, Yating (Female)" "zh-TW, Zhiwei (Male)"] }
def language-completer-1 [] { ["Arabic" "Chinese (Simplified)" "Czech" "Danish" "Dutch" "English" "Finnish" "French" "German" "Greek" "Hindi" "Hungarian" "Italian" "Japanese" "Klingon" "Korean" "Norweigan" "Polish" "Portuguese" "Russian" "Spanish" "Swedish" "Turkish" "Vietnamese" "Welsh"] }
def type-completer-3 [] { ["Both" "End" "Start"] }
def font-completer [] { ["Arial" "Arial Black" "Arial Narrow" "Book Antiqua" "Britannic Bold" "Brush Script MT" "Calisto MT" "Century Gothic" "Century Schoolbook" "Colonna MT" "Comic Sans MS" "Cooper Black" "Copperplate Gothic Bold" "Copperplate Gothic Light" "Courier New" "Edwardian Script ITC" "Engravers MT" "Franklin Gothic Demi" "Franklin Gothic Heavy" "Franklin Gothic Medium" "Garamond" "Georgia" "Gill Sans MT" "Gill Sans MT Condensed" "Gill Sans Ultra Bold" "Gill Sans Ultra Bold Condensed" "Goudy Old Style" "Haettenschweiler" "Holidays MT" "Impact" "Lucida Calligraphy" "Lucida Console" "Lucida Handwriting" "Lucida Sans Typewriter" "Lucida Sans Unicode" "MS Outlook" "Marlett" "Microsoft Sans Serif" "Palace Script MT" "Palatino Linotype" "Papyrus" "Playbill" "Rockwell" "Rockwell Condensed" "Rockwell Extra Bold" "Script MT Bold" "Stencil" "Symbol" "Tahoma" "Times New Roman" "Trebuchet MS" "Verdana" "Vivaldi" "Webdings" "Wingdings 1" "Wingdings 2" "Wingdings 3"] }
def horizontal-completer [] { ["Center" "Left" "Right"] }
def vertical-completer [] { ["Bottom" "Center" "Top"] }
def source-completer-11 [] { ["AUS Central Standard Time - (GMT+09:30) Darwin" "AUS Eastern Standard Time - (GMT+10:00) Canberra, Melbourne, Sydney" "Afghanistan Standard Time - (GMT+04:30) Kabul" "Alaskan Standard Time - (GMT-09:00) Alaska" "Arab Standard Time - (GMT+03:00) Kuwait, Riyadh" "Arabian Standard Time - (GMT+04:00) Abu Dhabi, Muscat" "Arabic Standard Time - (GMT+03:00) Baghdad" "Argentina Standard Time - (GMT-03:00) Buenos Aires" "Atlantic Standard Time - (GMT-04:00) Atlantic Time (Canada)" "Azerbaijan Standard Time - (GMT+04:00) Baku" "Azores Standard Time - (GMT-01:00) Azores" "Canada Central Standard Time - (GMT-06:00) Saskatchewan" "Cape Verde Standard Time - (GMT-01:00) Cape Verde Is." "Caucasus Standard Time - (GMT+04:00) Yerevan" "Cen. Australia Standard Time - (GMT+09:30) Adelaide" "Central America Standard Time - (GMT-06:00) Central America" "Central Asia Standard Time - (GMT+06:00) Astana, Dhaka" "Central Brazilian Standard Time - (GMT-04:00) Manaus" "Central Europe Standard Time - (GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague" "Central European Standard Time - (GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb" "Central Pacific Standard Time - (GMT+11:00) Magadan, Solomon Is., New Caledonia" "Central Standard Time (Mexico) - (GMT-06:00) Guadalajara, Mexico City, Monterrey" "Central Standard Time - (GMT-06:00) Central Time (US & Canada)" "China Standard Time - (GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi" "Dateline Standard Time - (GMT-12:00) International Date Line West" "E. Africa Standard Time - (GMT+03:00) Nairobi" "E. Australia Standard Time - (GMT+10:00) Brisbane" "E. Europe Standard Time - (GMT+02:00) Minsk" "E. South America Standard Time - (GMT-03:00) Brasilia" "Eastern Standard Time - (GMT-05:00) Eastern Time (US & Canada)" "Egypt Standard Time - (GMT+02:00) Cairo" "Ekaterinburg Standard Time - (GMT+05:00) Ekaterinburg" "FLE Standard Time - (GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius" "Fiji Standard Time - (GMT+12:00) Fiji, Kamchatka, Marshall Is." "GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" "GTB Standard Time - (GMT+02:00) Athens, Bucharest, Istanbul" "Georgian Standard Time - (GMT+03:00) Tbilisi" "Greenland Standard Time - (GMT-03:00) Greenland" "Greenwich Standard Time - (GMT) Monrovia, Reykjavik" "Hawaiian Standard Time - (GMT-10:00) Hawaii" "India Standard Time - (GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" "Iran Standard Time - (GMT+03:30) Tehran" "Israel Standard Time - (GMT+02:00) Jerusalem" "Korea Standard Time - (GMT+09:00) Seoul" "Mauritius Standard Time - (GMT+04:00) Port Louis" "Mid-Atlantic Standard Time - (GMT-02:00) Mid-Atlantic" "Middle East Standard Time - (GMT+02:00) Beirut" "Montevideo Standard Time - (GMT-03:00) Montevideo" "Mountain Standard Time (Mexico) - (GMT-07:00) Chihuahua, La Paz, Mazatlan" "Mountain Standard Time - (GMT-07:00) Mountain Time (US & Canada)" "Myanmar Standard Time - (GMT+06:30) Yangon (Rangoon)" "N. Central Asia Standard Time - (GMT+06:00) Almaty, Novosibirsk" "Namibia Standard Time - (GMT+02:00) Windhoek" "Nepal Standard Time - (GMT+05:45) Kathmandu" "New Zealand Standard Time - (GMT+12:00) Auckland, Wellington" "Newfoundland Standard Time - (GMT-03:30) Newfoundland" "North Asia East Standard Time - (GMT+08:00) Irkutsk, Ulaan Bataar" "North Asia Standard Time - (GMT+07:00) Krasnoyarsk" "Pacific SA Standard Time - (GMT-04:00) Santiago" "Pacific Standard Time (Mexico) - (GMT-08:00) Tijuana, Baja California" "Pacific Standard Time - (GMT-08:00) Pacific Time (US & Canada)" "Pakistan Standard Time - (GMT+05:00) Islamabad, Karachi" "Russian Standard Time - (GMT+03:00) Moscow, St. Petersburg, Volgograd" "SA Eastern Standard Time - (GMT-03:00) Georgetown" "SA Pacific Standard Time - (GMT-05:00) Bogota, Lima, Quito, Rio Branco" "SA Western Standard Time - (GMT-04:00) La Paz" "SE Asia Standard Time - (GMT+07:00) Bangkok, Hanoi, Jakarta" "Samoa Standard Time - (GMT-11:00) Midway Island, Samoa" "Singapore Standard Time - (GMT+08:00) Kuala Lumpur, Singapore" "South Africa Standard Time - (GMT+02:00) Harare, Pretoria" "Sri Lanka Standard Time - (GMT+05:30) Sri Jayawardenepura" "Taipei Standard Time - (GMT+08:00) Taipei" "Tasmania Standard Time - (GMT+10:00) Hobart" "Tokyo Standard Time - (GMT+09:00) Osaka, Sapporo, Tokyo" "Tonga Standard Time - (GMT+13:00) Nuku'alofa" "US Eastern Standard Time - (GMT-05:00) Indiana (East)" "US Mountain Standard Time - (GMT-07:00) Arizona" "Venezuela Standard Time - (GMT-04:30) Caracas" "Vladivostok Standard Time - (GMT+10:00) Vladivostok" "W. Australia Standard Time - (GMT+08:00) Perth" "W. Central Africa Standard Time - (GMT+01:00) West Central Africa" "W. Europe Standard Time - (GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" "West Asia Standard Time - (GMT+05:00) Tashkent" "West Pacific Standard Time - (GMT+10:00) Guam, Port Moresby" "Yakutsk Standard Time - (GMT+09:00) Yakutsk"] }
def target-completer-11 [] { ["AUS Central Standard Time - (GMT+09:30) Darwin" "AUS Eastern Standard Time - (GMT+10:00) Canberra, Melbourne, Sydney" "Afghanistan Standard Time - (GMT+04:30) Kabul" "Alaskan Standard Time - (GMT-09:00) Alaska" "Arab Standard Time - (GMT+03:00) Kuwait, Riyadh" "Arabian Standard Time - (GMT+04:00) Abu Dhabi, Muscat" "Arabic Standard Time - (GMT+03:00) Baghdad" "Argentina Standard Time - (GMT-03:00) Buenos Aires" "Atlantic Standard Time - (GMT-04:00) Atlantic Time (Canada)" "Azerbaijan Standard Time - (GMT+04:00) Baku" "Azores Standard Time - (GMT-01:00) Azores" "Canada Central Standard Time - (GMT-06:00) Saskatchewan" "Cape Verde Standard Time - (GMT-01:00) Cape Verde Is." "Caucasus Standard Time - (GMT+04:00) Yerevan" "Cen. Australia Standard Time - (GMT+09:30) Adelaide" "Central America Standard Time - (GMT-06:00) Central America" "Central Asia Standard Time - (GMT+06:00) Astana, Dhaka" "Central Brazilian Standard Time - (GMT-04:00) Manaus" "Central Europe Standard Time - (GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague" "Central European Standard Time - (GMT+01:00) Sarajevo, Skopje, Warsaw, Zagreb" "Central Pacific Standard Time - (GMT+11:00) Magadan, Solomon Is., New Caledonia" "Central Standard Time (Mexico) - (GMT-06:00) Guadalajara, Mexico City, Monterrey" "Central Standard Time - (GMT-06:00) Central Time (US & Canada)" "China Standard Time - (GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi" "Dateline Standard Time - (GMT-12:00) International Date Line West" "E. Africa Standard Time - (GMT+03:00) Nairobi" "E. Australia Standard Time - (GMT+10:00) Brisbane" "E. Europe Standard Time - (GMT+02:00) Minsk" "E. South America Standard Time - (GMT-03:00) Brasilia" "Eastern Standard Time - (GMT-05:00) Eastern Time (US & Canada)" "Egypt Standard Time - (GMT+02:00) Cairo" "Ekaterinburg Standard Time - (GMT+05:00) Ekaterinburg" "FLE Standard Time - (GMT+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius" "Fiji Standard Time - (GMT+12:00) Fiji, Kamchatka, Marshall Is." "GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" "GTB Standard Time - (GMT+02:00) Athens, Bucharest, Istanbul" "Georgian Standard Time - (GMT+03:00) Tbilisi" "Greenland Standard Time - (GMT-03:00) Greenland" "Greenwich Standard Time - (GMT) Monrovia, Reykjavik" "Hawaiian Standard Time - (GMT-10:00) Hawaii" "India Standard Time - (GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" "Iran Standard Time - (GMT+03:30) Tehran" "Israel Standard Time - (GMT+02:00) Jerusalem" "Korea Standard Time - (GMT+09:00) Seoul" "Mauritius Standard Time - (GMT+04:00) Port Louis" "Mid-Atlantic Standard Time - (GMT-02:00) Mid-Atlantic" "Middle East Standard Time - (GMT+02:00) Beirut" "Montevideo Standard Time - (GMT-03:00) Montevideo" "Mountain Standard Time (Mexico) - (GMT-07:00) Chihuahua, La Paz, Mazatlan" "Mountain Standard Time - (GMT-07:00) Mountain Time (US & Canada)" "Myanmar Standard Time - (GMT+06:30) Yangon (Rangoon)" "N. Central Asia Standard Time - (GMT+06:00) Almaty, Novosibirsk" "Namibia Standard Time - (GMT+02:00) Windhoek" "Nepal Standard Time - (GMT+05:45) Kathmandu" "New Zealand Standard Time - (GMT+12:00) Auckland, Wellington" "Newfoundland Standard Time - (GMT-03:30) Newfoundland" "North Asia East Standard Time - (GMT+08:00) Irkutsk, Ulaan Bataar" "North Asia Standard Time - (GMT+07:00) Krasnoyarsk" "Pacific SA Standard Time - (GMT-04:00) Santiago" "Pacific Standard Time (Mexico) - (GMT-08:00) Tijuana, Baja California" "Pacific Standard Time - (GMT-08:00) Pacific Time (US & Canada)" "Pakistan Standard Time - (GMT+05:00) Islamabad, Karachi" "Russian Standard Time - (GMT+03:00) Moscow, St. Petersburg, Volgograd" "SA Eastern Standard Time - (GMT-03:00) Georgetown" "SA Pacific Standard Time - (GMT-05:00) Bogota, Lima, Quito, Rio Branco" "SA Western Standard Time - (GMT-04:00) La Paz" "SE Asia Standard Time - (GMT+07:00) Bangkok, Hanoi, Jakarta" "Samoa Standard Time - (GMT-11:00) Midway Island, Samoa" "Singapore Standard Time - (GMT+08:00) Kuala Lumpur, Singapore" "South Africa Standard Time - (GMT+02:00) Harare, Pretoria" "Sri Lanka Standard Time - (GMT+05:30) Sri Jayawardenepura" "Taipei Standard Time - (GMT+08:00) Taipei" "Tasmania Standard Time - (GMT+10:00) Hobart" "Tokyo Standard Time - (GMT+09:00) Osaka, Sapporo, Tokyo" "Tonga Standard Time - (GMT+13:00) Nuku'alofa" "US Eastern Standard Time - (GMT-05:00) Indiana (East)" "US Mountain Standard Time - (GMT-07:00) Arizona" "Venezuela Standard Time - (GMT-04:30) Caracas" "Vladivostok Standard Time - (GMT+10:00) Vladivostok" "W. Australia Standard Time - (GMT+08:00) Perth" "W. Central Africa Standard Time - (GMT+01:00) West Central Africa" "W. Europe Standard Time - (GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" "West Asia Standard Time - (GMT+05:00) Tashkent" "West Pacific Standard Time - (GMT+10:00) Guam, Port Moresby" "Yakutsk Standard Time - (GMT+09:00) Yakutsk"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    add-to-collection: "record<result: list<string>>"
    csv-to-json: "record<result: string>"
    calculate-absolute: "record<result: float>"
    calculate-addition: "record<result: float>"
    calculate-average: "record<result: float>"
    calculate-cosine: "record<result: float>"
    calculate-division: "record<result: float>"
    calculate-logarithm: "record<result: float>"
    calculate-median: "record<result: float>"
    calculate-min-max: "record<result: float>"
    calculate-modulo: "record<result: float>"
    calculate-multiplication: "record<result: float>"
    calculate-nth-root: "record<result: float>"
    calculate-power: "record<result: float>"
    calculate-sine: "record<result: float>"
    calculate-square-root: "record<result: float>"
    calculate-subtraction: "record<result: float>"
    calculate-sum: "record<result: float>"
    calculate-tangent: "record<result: float>"
    calculate-variance: "record<result: float>"
    collection-contains-number: "record<item: float, items: list<float>, status: bool>"
    collection-contains-string: "record<item: string, items: list<string>, status: bool>"
    collection-ends-with-string: "record<item: string, items: list<string>, status: bool>"
    collection-starts-with-string: "record<item: string, items: list<string>, status: bool>"
    collection-to-json: "record<result: string>"
    collection-to-xml: "record<result: string>"
    compare-strings: "record<result: string>"
    contains-string: "record<result: string>"
    convert-angle: "record<result: float>"
    convert-area: "record<result: float>"
    convert-case: "record<result: string>"
    convert-currency: "record<result: float>"
    convert-distance: "record<result: float>"
    convert-duration: "record<result: float>"
    convert-energy: "record<result: float>"
    convert-image: "binary"
    convert-power: "record<result: float>"
    convert-speed: "record<result: float>"
    convert-temperature: "record<result: float>"
    convert-volume: "record<result: float>"
    convert-weight: "record<result: float>"
    count-collection: "record<result: float>"
    crop-image: "binary"
    date-time-difference: "record<days: float, hours: float, milliseconds: float, minutes: float, months: float, ticks: float, totalDays: float, totalHours: float, totalMilliseconds: float, totalMinutes: float, totalMonths: float, totalSeconds: float, totalYears: float, years: float>"
    date-time-info: "record<DayOfWeek: float, DayOfYear: float, MinutesInDay: float, SecondsInDay: float, Ticks: float, WeekOfYear: float>"
    decode-string: "record<result: string>"
    encode-string: "record<result: string>"
    file-to-string: "record<result: string>"
    filter-collection: "record<result: list<string>>"
    flip-image: "binary"
    format-currency: "record<result: string>"
    format-date-time: "record<result: string>"
    generate-guid: "record<result: string>"
    generate-hash: "record<result: string>"
    generate-qr-code: "binary"
    json-to-csv: "record<result: string>"
    json-to-html: "record<result: string>"
    json-to-xml: "record<result: string>"
    join-strings: "record<result: string>"
    market-index: "record<adj_close: float, adj_high: float, adj_low: float, adj_open: float, adj_volume: float, close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float>"
    query-json: "record<result: string>"
    query-xml: "record<result: string>"
    random-number: "record<result: float>"
    redact-string: "record<result: string>"
    remove-from-collection: "record<result: list<string>>"
    replace-string: "record<result: string>"
    replace-values-in-collection: "record<result: list<string>>"
    resize-image: "binary"
    rotate-image: "binary"
    round-number: "record<result: float>"
    shorten-link: "record<result: string>"
    sort-collection: "record<result: list<string>>"
    speech-to-text: "record<result: string>"
    split-collection: "record<result1: list<string>, result2: list<string>>"
    split-string: "record<data: list<string>>"
    standard-deviation: "record<result: float>"
    stock-prices: "record<result: table<close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float>>"
    string-to-file: "binary"
    text-to-speech: "binary"
    translate-string: "record<result: string>"
    trim-string: "record<result: string>"
    url-decode: "record<result: string>"
    url-encode: "record<result: string>"
    validate-email: "record<result: string>"
    verify-hash: "record<result: bool>"
    watermark-image: "binary"
    world-time: "record<result: string>"
    xml-to-json: "record<result: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-to-collection" "csv-to-json" "calculate-absolute" "calculate-addition" "calculate-average" "calculate-cosine" "calculate-division" "calculate-logarithm" "calculate-median" "calculate-min-max" "calculate-modulo" "calculate-multiplication" "calculate-nth-root" "calculate-power" "calculate-sine" "calculate-square-root" "calculate-subtraction" "calculate-sum" "calculate-tangent" "calculate-variance" "collection-contains-number" "collection-contains-string" "collection-ends-with-string" "collection-starts-with-string" "collection-to-json" "collection-to-xml" "compare-strings" "contains-string" "convert-angle" "convert-area" "convert-case" "convert-currency" "convert-distance" "convert-duration" "convert-energy" "convert-image" "convert-power" "convert-speed" "convert-temperature" "convert-volume" "convert-weight" "count-collection" "crop-image" "date-time-difference" "date-time-info" "decode-string" "encode-string" "file-to-string" "filter-collection" "flip-image" "format-currency" "format-date-time" "generate-guid" "generate-hash" "generate-qr-code" "json-to-csv" "json-to-html" "json-to-xml" "join-strings" "market-index" "query-json" "query-xml" "random-number" "redact-string" "remove-from-collection" "replace-string" "replace-values-in-collection" "resize-image" "rotate-image" "round-number" "shorten-link" "sort-collection" "speech-to-text" "split-collection" "split-string" "standard-deviation" "stock-prices" "string-to-file" "text-to-speech" "translate-string" "trim-string" "url-decode" "url-encode" "validate-email" "verify-hash" "watermark-image" "world-time" "xml-to-json" "commands"] | sort) } | get name | first)
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

# Collections - Add to collection
#
# POST /AddToCollection
# Returns: record<result: list<string>>
# operationId: AddToCollection
export def "add-to-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index position for operation (leave blank to specify end of collection)
  input: list<string> # Collection of values or objects to modify
  --item: string # Item (for multiple items, leave blank and use Items)
  --items: list<string> # Items (Collection, for a single item leave blank and use Item)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/AddToCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: index, var: index}, {name: input, var: input}, {name: item, var: item}, {name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    index: $index, input: $input, item: $item, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - CSV to JSON
#
# POST /CSVtoJSON
# Returns: record<result: string>
# operationId: CsvToJson
export def "csv-to-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # CSV string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CSVtoJSON"
    body: {content_type: "application/json", kind: json, fields: [{name: header, var: header, required: true}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    header: $header, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Absolute
#
# POST /CalculateAbsolute
# Returns: record<result: float>
# operationId: CalculateAbsolute
export def "calculate-absolute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateAbsolute"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Addition
#
# POST /CalculateAddition
# Returns: record<result: float>
# operationId: CalculateAddition
export def "calculate-addition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateAddition"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate average
#
# POST /CalculateAverage
# Returns: record<result: float>
# operationId: CalculateAverage
export def "calculate-average" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateAverage"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Cosine
#
# POST /CalculateCosine
# Returns: record<result: float>
# operationId: CalculateCosine
export def "calculate-cosine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateCosine"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Division
#
# POST /CalculateDivision
# Returns: record<result: float>
# operationId: CalculateDivision
export def "calculate-division" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateDivision"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Logarithm
#
# POST /CalculateLogarithm
# Returns: record<result: float>
# operationId: CalculateLogarithm
export def "calculate-logarithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateLogarithm"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate median
#
# POST /CalculateMedian
# Returns: record<result: float>
# operationId: CalculateMedian
export def "calculate-median" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateMedian"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate minimum or maximum
#
# POST /CalculateMinMax
# Returns: record<result: float>
# operationId: CalculateMinMax
export def "calculate-min-max" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<float> # Colllection of values to calculate
  type: string@type-completer # Minimum or Maximum (default: Minimum)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateMinMax"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Modulo
#
# POST /CalculateModulo
# Returns: record<result: float>
# operationId: CalculateModulo
export def "calculate-modulo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateModulo"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Multiplication
#
# POST /CalculateMultiplication
# Returns: record<result: float>
# operationId: CalculateMultiplication
export def "calculate-multiplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateMultiplication"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Nth Root
#
# POST /CalculateNthRoot
# Returns: record<result: float>
# operationId: CalculateNthRoot
export def "calculate-nth-root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateNthRoot"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate power
#
# POST /CalculatePower
# Returns: record<result: float>
# operationId: CalculatePower
export def "calculate-power" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Number to raise
  power: float # Power
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculatePower"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: power, var: power}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, power: $power
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Sine
#
# POST /CalculateSine
# Returns: record<result: float>
# operationId: CalculateSine
export def "calculate-sine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateSine"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Square Root
#
# POST /CalculateSquareRoot
# Returns: record<result: float>
# operationId: CalculateSquareRoot
export def "calculate-square-root" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateSquareRoot"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Subtraction
#
# POST /CalculateSubtraction
# Returns: record<result: float>
# operationId: CalculateSubtraction
export def "calculate-subtraction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value
  value: float # Addend, subtrahend, factor, divisor or radicand
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateSubtraction"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate sum
#
# POST /CalculateSum
# Returns: record<result: float>
# operationId: CalculateSum
export def "calculate-sum" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateSum"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate Tangent
#
# POST /CalculateTangent
# Returns: record<result: float>
# operationId: CalculateTangent
export def "calculate-tangent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateTangent"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate variance
#
# POST /CalculateVariance
# Returns: record<result: float>
# operationId: CalculateVariance
export def "calculate-variance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CalculateVariance"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Contains number
#
# POST /CollectionContainsNumber
# Returns: record<item: float, items: list<float>, status: bool>
# operationId: CollectionContainsNumber
export def "collection-contains-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<float> # Collection of strings to search
  match: float # Number to match
  --type: string@type-completer-1 # Type of number - integer or decimal (default: Integer)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionContainsNumber"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: match, var: match}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, match: $match, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Contains string
#
# POST /CollectionContainsString
# Returns: record<item: string, items: list<string>, status: bool>
# operationId: CollectionContainsString
export def "collection-contains-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionContainsString"
    body: {content_type: "application/json", kind: json, fields: [{name: ignorecase, var: ignorecase}, {name: input, var: input}, {name: match, var: match}, {name: trim, var: trim}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    ignorecase: $ignorecase, input: $input, match: $match, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Ends with string
#
# POST /CollectionEndsWithString
# Returns: record<item: string, items: list<string>, status: bool>
# operationId: CollectionEndsWithString
export def "collection-ends-with-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionEndsWithString"
    body: {content_type: "application/json", kind: json, fields: [{name: ignorecase, var: ignorecase}, {name: input, var: input}, {name: match, var: match}, {name: trim, var: trim}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    ignorecase: $ignorecase, input: $input, match: $match, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Starts with string
#
# POST /CollectionStartsWithString
# Returns: record<item: string, items: list<string>, status: bool>
# operationId: CollectionStartsWithString
export def "collection-starts-with-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignorecase: string@ignorecase-completer # Ignore case when performing comparison
  input: list<string> # Collection of strings to search
  match: string # Text to match
  --trim: string@trim-completer # Trim white space from comparison string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionStartsWithString"
    body: {content_type: "application/json", kind: json, fields: [{name: ignorecase, var: ignorecase}, {name: input, var: input}, {name: match, var: match}, {name: trim, var: trim}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    ignorecase: $ignorecase, input: $input, match: $match, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Collection to JSON
#
# POST /CollectionToJSON
# Returns: record<result: string>
# operationId: CollectionToJSON
export def "collection-to-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection containing strings to convert
  name: string # Collection name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionToJSON"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Collection to XML
#
# POST /CollectionToXML
# Returns: record<result: string>
# operationId: CollectionToXml
export def "collection-to-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  child: string # Name of child XML node(s)
  input: list<string> # Collection containing strings to convert
  root: string # Name of root XML node
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CollectionToXML"
    body: {content_type: "application/json", kind: json, fields: [{name: child, var: child}, {name: input, var: input}, {name: root, var: root}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    child: $child, input: $input, root: $root
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Compare strings
#
# POST /CompareStrings
# Returns: record<result: string>
# operationId: CompareStrings
export def "compare-strings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  compare: string # Comparison string
  input: string # Original string
  lower: string@lower-completer # Convert strings to lowercase before comparison
  trim: string@trim-completer # Trim strings before comparison
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CompareStrings"
    body: {content_type: "application/json", kind: json, fields: [{name: compare, var: compare}, {name: input, var: input}, {name: lower, var: lower}, {name: trim, var: trim}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    compare: $compare, input: $input, lower: $lower, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Contains string
#
# POST /ContainsString
# Returns: record<result: string>
# operationId: ContainsString
export def "contains-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  find: string # Text to match
  input: string # Text to search
  lower: string@lower-completer # Convert strings to lowercase
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ContainsString"
    body: {content_type: "application/json", kind: json, fields: [{name: find, var: find}, {name: input, var: input}, {name: lower, var: lower}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    find: $find, input: $input, lower: $lower
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert angle
#
# POST /ConvertAngle
# Returns: record<result: float>
# operationId: ConvertAngle
export def "convert-angle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer
  target: string@target-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertAngle"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert area
#
# POST /ConvertArea
# Returns: record<result: float>
# operationId: ConvertArea
export def "convert-area" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-1
  target: string@target-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertArea"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Convert case
#
# POST /ConvertCase
# Returns: record<result: string>
# operationId: ConvertCase
export def "convert-case" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alphacase: string@alphacase-completer # Case of conversion result
  input: string # String containing the text to convert
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertCase"
    body: {content_type: "application/json", kind: json, fields: [{name: alphacase, var: alphacase}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    alphacase: $alphacase, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Currency - Convert currency
#
# POST /ConvertCurrency
# Returns: record<result: float>
# operationId: ConvertCurrency
export def "convert-currency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float # Amount to convert
  source: string@source-completer-2 # default: USD
  target: string@target-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertCurrency"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert distance
#
# POST /ConvertDistance
# Returns: record<result: float>
# operationId: ConvertDistance
export def "convert-distance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-3
  target: string@target-completer-3
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertDistance"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert duration
#
# POST /ConvertDuration
# Returns: record<result: float>
# operationId: ConvertDuration
export def "convert-duration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-4
  target: string@target-completer-4
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertDuration"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert energy
#
# POST /ConvertEnergy
# Returns: record<result: float>
# operationId: ConvertEnergy
export def "convert-energy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-5
  target: string@target-completer-5
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertEnergy"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Convert Image
#
# POST /ConvertImage
# Returns: binary
# operationId: ConvertImage
export def "convert-image" [
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
  file: string # Source image file (format: binary)
  format: string@format-completer # Output file format (default: PNG)
]: any -> any {
  $in | http-request {
    method: post
    path: "/ConvertImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: format, var: format}], files: [file]}
    accept: ["image/bmp", "image/gif", "image/jpeg", "image/png"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    file: $file, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Math - Convert power
#
# POST /ConvertPower
# Returns: record<result: float>
# operationId: ConvertPower
export def "convert-power" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-6
  target: string@target-completer-6
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertPower"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert speed
#
# POST /ConvertSpeed
# Returns: record<result: float>
# operationId: ConvertSpeed
export def "convert-speed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-7
  target: string@target-completer-7
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertSpeed"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert temperature
#
# POST /ConvertTemperature
# Returns: record<result: float>
# operationId: ConvertTemperature
export def "convert-temperature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-8
  target: string@target-completer-8
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertTemperature"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert volume
#
# POST /ConvertVolume
# Returns: record<result: float>
# operationId: ConvertVolume
export def "convert-volume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-9
  target: string@target-completer-9
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertVolume"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Convert weight
#
# POST /ConvertWeight
# Returns: record<result: float>
# operationId: ConvertWeight
export def "convert-weight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float
  source: string@source-completer-10
  target: string@target-completer-10
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ConvertWeight"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Count collection
#
# POST /CountCollection
# Returns: record<result: float>
# operationId: CountCollection
export def "count-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of items to count
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CountCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Crop Image
#
# POST /CropImage
# Returns: binary
# operationId: CropImage
export def "crop-image" [
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
  height: float # Height (Y-axis down, negative to reverse)
  width: float # Width (X-axis right, negative to reverse)
  file: string # Source image file (format: binary)
  position: string@position-completer # Crop start position (use negative values to reverse crop area) (default: TopLeft)
]: any -> any {
  $in | http-request {
    method: post
    path: "/CropImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: Height, var: height}, {name: Width, var: width}, {name: file, var: file}, {name: position, var: position}], files: [file]}
    accept: ["image/bmp", "image/gif", "image/jpeg", "image/png"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    height: $height, width: $width, file: $file, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DateTime - DateTime difference
#
# POST /DateTimeDifference
# Returns: record<days: float, hours: float, milliseconds: float, minutes: float, months: float, ticks: float, totalDays: float, totalHours: float, totalMilliseconds: float, totalMinutes: float, totalMonths: float, totalSeconds: float, totalYears: float, years: float>
# operationId: DateTimeDifference
export def "date-time-difference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  date_time1: string # First date/time value
  date_time2: string # Second date/time value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DateTimeDifference"
    body: {content_type: "application/json", kind: json, fields: [{name: dateTime1, var: date_time1}, {name: dateTime2, var: date_time2}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    date_time1: $date_time1, date_time2: $date_time2
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DateTime - Get date and time information
#
# POST /DateTimeInfo
# Returns: record<DayOfWeek: float, DayOfYear: float, MinutesInDay: float, SecondsInDay: float, Ticks: float, WeekOfYear: float>
# operationId: DateTimeInfo
export def "date-time-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string@culture-completer # Language culture (default: en-US)
  input: string # Source date and time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DateTimeInfo"
    body: {content_type: "application/json", kind: json, fields: [{name: culture, var: culture}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    culture: $culture, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Decode string
#
# POST /DecodeString
# Returns: record<result: string>
# operationId: DecodeString
export def "decode-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # Encoded string variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DecodeString"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Encode string
#
# POST /EncodeString
# Returns: record<result: string>
# operationId: EncodeString
export def "encode-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # String variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/EncodeString"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - File to string
#
# POST /FileToString
# Returns: record<result: string>
# operationId: FileToString
export def "file-to-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source file (10MB limit) (format: binary)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/FileToString"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Filter collection
#
# POST /FilterCollection
# Returns: record<result: list<string>>
# operationId: FilterCollection
export def "filter-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to filter
  keywords: string # Keywords (separate multiple values with commas)
  match: string@match-completer # Match type (default: Any)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/FilterCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: keywords, var: keywords}, {name: match, var: match}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, keywords: $keywords, match: $match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Flip Image
#
# POST /FlipImage
# Returns: binary
# operationId: FlipImage
export def "flip-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source image file (format: binary)
  orientation: string@orientation-completer # Horizontal or Vertical (default: Horizontal)
]: any -> any {
  $in | http-request {
    method: post
    path: "/FlipImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: orientation, var: orientation}], files: [file]}
    accept: ["*/*"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    file: $file, orientation: $orientation
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Currency - Format currency
#
# POST /FormatCurrency
# Returns: record<result: string>
# operationId: FormatCurrency
export def "format-currency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: float # Amount to format
  target: string@target-completer-2
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/FormatCurrency"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DateTime - Format date and time
#
# POST /FormatDateTime
# Returns: record<result: string>
# operationId: FormatDateTime
export def "format-date-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string@culture-completer # Language culture (default: en-US)
  format: string # Output format
  input: string # Source date and time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/FormatDateTime"
    body: {content_type: "application/json", kind: json, fields: [{name: culture, var: culture}, {name: format, var: format}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    culture: $culture, format: $format, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Generate GUID
#
# POST /GenerateGuid
# Returns: record<result: string>
# operationId: GenerateGuid
export def "generate-guid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uppercase: string@uppercase-completer # All uppercase alpha characters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/GenerateGuid"
    body: {content_type: "application/json", kind: json, fields: [{name: uppercase, var: uppercase}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    uppercase: $uppercase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Generate hash
#
# POST /GenerateHash
# Returns: record<result: string>
# operationId: GenerateHash
export def "generate-hash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: string@algorithm-completer # Hash algorithm
  input: string # Hash source string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/GenerateHash"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    algorithm: $algorithm, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Generate QR code
#
# POST /GenerateQRCode
# Returns: binary
# operationId: GenerateQRCode
export def "generate-qr-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # Text value(s) (vertical bar delimited by type)
  payload: string@payload-completer # Payload type (default: Plain Text (string))
]: any -> any {
  $in | http-request {
    method: post
    path: "/GenerateQRCode"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: payload, var: payload}]}
    accept: ["image/png"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, payload: $payload
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - JSON to CSV
#
# POST /JSONtoCSV
# Returns: record<result: string>
# operationId: JsonToCsv
export def "json-to-csv" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # JSON array object
  --omit: string # Columns to omit (comma separated)
  --order: string # Column order (comma separated)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/JSONtoCSV"
    body: {content_type: "application/json", kind: json, fields: [{name: header, var: header, required: true}, {name: input, var: input}, {name: omit, var: omit}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    header: $header, input: $input, omit: $omit, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - JSON to HTML Table
#
# POST /JSONtoHTML
# Returns: record<result: string>
# operationId: JsonToHtml
export def "json-to-html" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alternate: string # Alternate header row markup
  --attributes: string # Optional table attributes (single quoted values)
  --header: oneof<nothing, bool> # Include header row (default: true)
  input: string # JSON array object
  --omit: string # Columns to omit (comma separated)
  --order: string # Column order (comma separated)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/JSONtoHTML"
    body: {content_type: "application/json", kind: json, fields: [{name: alternate, var: alternate}, {name: attributes, var: attributes}, {name: header, var: header, required: true}, {name: input, var: input}, {name: omit, var: omit}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    alternate: $alternate, attributes: $attributes, header: $header, input: $input, omit: $omit, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - JSON to XML
#
# POST /JSONtoXML
# Returns: record<result: string>
# operationId: JsonToXml
export def "json-to-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # JSON array object
  root: string # Name of root node
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/JSONtoXML"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: root, var: root}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, root: $root
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Join strings
#
# POST /JoinStrings
# Returns: record<result: string>
# operationId: JoinStrings
export def "join-strings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to be joined
  lower: string@lower-completer # Convert strings in collection to lowercase
  separator: string # Separator character
  trim: string@trim-completer # Trim strings in collection
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/JoinStrings"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: lower, var: lower}, {name: separator, var: separator}, {name: trim, var: trim}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, lower: $lower, separator: $separator, trim: $trim
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finance - Market index
#
# POST /MarketIndex
# Returns: record<adj_close: float, adj_high: float, adj_low: float, adj_open: float, adj_volume: float, close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float>
# operationId: MarketIndex
export def "market-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date (yyyy-MM-dd, leave empty for last trading day)
  symbol: string@symbol-completer # Market index
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/MarketIndex"
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}, {name: symbol, var: symbol}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    date: $date, symbol: $symbol
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - Query JSON
#
# POST /QueryJSON
# Returns: record<result: string>
# operationId: QueryJson
export def "query-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML or JSON string
  query: string # XPath or JSONPath query
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/QueryJSON"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - Query XML
#
# POST /QueryXML
# Returns: record<result: string>
# operationId: QueryXml
export def "query-xml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML or JSON string
  query: string # XPath or JSONPath query
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/QueryXML"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Random number
#
# POST /RandomNumber
# Returns: record<result: float>
# operationId: RandomNumber
export def "random-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  end: float # End of range
  start: float # Start of range
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RandomNumber"
    body: {content_type: "application/json", kind: json, fields: [{name: end, var: end}, {name: start, var: start}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    end: $end, start: $start
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Redact string
#
# POST /RedactString
# Returns: record<result: string>
# operationId: RedactString
export def "redact-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regex: string # Regular expression pattern for matching strings
  source: string # String containing the complete text
  --value: string # Individual string to redact
  --values: list<string> # Collection of strings to redact
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RedactString"
    body: {content_type: "application/json", kind: json, fields: [{name: regex, var: regex}, {name: source, var: source}, {name: value, var: value}, {name: values, var: values}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    regex: $regex, source: $source, value: $value, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Remove from collection
#
# POST /RemoveFromCollection
# Returns: record<result: list<string>>
# operationId: RemoveFromCollection
export def "remove-from-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index position for operation (leave blank to specify end of collection)
  input: list<string> # Collection of values or objects to modify
  --item: string # Item (for multiple items, leave blank and use Items)
  --items: list<string> # Items (Collection, for a single item leave blank and use Item)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RemoveFromCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: index, var: index}, {name: input, var: input}, {name: item, var: item}, {name: items, var: items}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    index: $index, input: $input, item: $item, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Replace string
#
# POST /ReplaceString
# Returns: record<result: string>
# operationId: ReplaceString
export def "replace-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  replacement: string # Replacement text
  source: string # String containing the text to be replaced
  value: string # Text to replace
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ReplaceString"
    body: {content_type: "application/json", kind: json, fields: [{name: replacement, var: replacement}, {name: source, var: source}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    replacement: $replacement, source: $source, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Replace values in collection
#
# POST /ReplaceValuesInCollection
# Returns: record<result: list<string>>
# operationId: ReplaceValuesInCollection
export def "replace-values-in-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ignore_case: string@ignore-case-completer # Ignore case (default: true)
  input: list<string> # Collection of strings
  match: string # Match value
  replacement: string # Replacement value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ReplaceValuesInCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: ignoreCase, var: ignore_case}, {name: input, var: input}, {name: match, var: match}, {name: replacement, var: replacement}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    ignore_case: $ignore_case, input: $input, match: $match, replacement: $replacement
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Resize Image
#
# POST /ResizeImage
# Returns: binary
# operationId: ResizeImage
export def "resize-image" [
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
  algorithm: string@algorithm-completer-1 # Optimize output quality of the target image (default: Bicubic (default))
  file: string # Source image file (format: binary)
  --height: float # Image height (pixels or percent)
  units: string@units-completer # Image adjustment units (default: Pixels)
  --width: float # Image width (pixels or percent)
]: any -> any {
  $in | http-request {
    method: post
    path: "/ResizeImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: algorithm, var: algorithm}, {name: file, var: file}, {name: height, var: height}, {name: units, var: units}, {name: width, var: width}], files: [file]}
    accept: ["image/bmp", "image/gif", "image/jpeg", "image/png"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    algorithm: $algorithm, file: $file, height: $height, units: $units, width: $width
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Files - Rotate Image
#
# POST /RotateImage
# Returns: binary
# operationId: RotateImage
export def "rotate-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  degrees: string # Number of degrees
  file: string # Source image file (format: binary)
]: any -> any {
  $in | http-request {
    method: post
    path: "/RotateImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: degrees, var: degrees}, {name: file, var: file}], files: [file]}
    accept: ["*/*"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    degrees: $degrees, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Round number
#
# POST /RoundNumber
# Returns: record<result: float>
# operationId: RoundNumber
export def "round-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: float # Numeric value to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RoundNumber"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Shorten hyperlink
#
# POST /ShortenLink
# Returns: record<result: string>
# operationId: ShortenLink
export def "shorten-link" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # String variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ShortenLink"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Sort collection
#
# POST /SortCollection
# Returns: record<result: list<string>>
# operationId: SortCollection
export def "sort-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: list<string> # Collection of strings to sort
  order: string@order-completer # Sort order (default: Ascending)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/SortCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: order, var: order}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Speech to Text
#
# POST /SpeechToText
# Returns: record<result: string>
# operationId: SpeechToText
export def "speech-to-text" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Source audio file (WAV, MP3, AAC, M4A) (format: binary)
  language: string@language-completer # Language of audio input (default: English (United States))
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/SpeechToText"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}, {name: language, var: language}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    file: $file, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Collections - Split collection
#
# POST /SplitCollection
# Returns: record<result1: list<string>, result2: list<string>>
# operationId: SplitCollection
export def "split-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --index: string # Index location to split (leave empty to use Match value)
  input: list<string> # Collection of items to split
  --match: string # String to match (explicit, case-insensitive, leave empty to use Index)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/SplitCollection"
    body: {content_type: "application/json", kind: json, fields: [{name: index, var: index}, {name: input, var: input}, {name: match, var: match}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    index: $index, input: $input, match: $match
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Split string
#
# POST /SplitString
# Returns: record<data: list<string>>
# operationId: SplitString
export def "split-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  characters: string # One or more characters that will be used to split the text
  input: string # Text to split
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/SplitString"
    body: {content_type: "application/json", kind: json, fields: [{name: characters, var: characters}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    characters: $characters, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Math - Calculate standard deviation
#
# POST /StandardDeviation
# Returns: record<result: float>
# operationId: StandardDeviation
export def "standard-deviation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  decimals: float # Round to number of decimal places
  input: list<float> # Colllection of values to calculate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StandardDeviation"
    body: {content_type: "application/json", kind: json, fields: [{name: decimals, var: decimals}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    decimals: $decimals, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finance - Stock prices
#
# POST /StockPrices
# Returns: record<result: table<close: float, date: string, exchange: string, high: float, low: float, open: float, symbol: string, volume: float>>
# operationId: StockPrices
export def "stock-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date (yyyy-MM-dd, leave empty for latest)
  --exchange: string@exchange-completer # Stock exchange
  symbols: string # Stock ticker symbols (comma-separated, max 20)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StockPrices"
    body: {content_type: "application/json", kind: json, fields: [{name: date, var: date}, {name: exchange, var: exchange}, {name: symbols, var: symbols}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    date: $date, exchange: $exchange, symbols: $symbols
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - String to File
#
# POST /StringToFile
# Returns: binary
# operationId: StringToFile
export def "string-to-file" [
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
  extension: string@extension-completer # File extension (default: TXT)
  filename: string # Name of file (without extension)
  input: string # Text string (body of file)
]: any -> any {
  $in | http-request {
    method: post
    path: "/StringToFile"
    body: {content_type: "application/json", kind: json, fields: [{name: extension, var: extension}, {name: filename, var: filename}, {name: input, var: input}]}
    accept: ["application/json", "application/xml", "text/css", "text/csv", "text/html", "text/javascript", "text/plain"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    extension: $extension, filename: $filename, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Text - Text to Speech
#
# POST /TextToSpeech
# Returns: binary
# operationId: TextToSpeech
export def "text-to-speech" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text to convert (10,000 characters max)
  type: string@type-completer-2 # Text or file type (default: PlainText)
  voice: string@voice-completer # Voice locale (must match language of input text) (default: en-US, Aria (Female))
]: any -> any {
  $in | http-request {
    method: post
    path: "/TextToSpeech"
    body: {content_type: "application/json", kind: json, fields: [{name: text, var: text}, {name: type, var: type}, {name: voice, var: voice}]}
    accept: ["audio/mp3"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    text: $text, type: $type, voice: $voice
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Translate string
#
# POST /TranslateString
# Returns: record<result: string>
# operationId: TranslateString
export def "translate-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # String containing the text to be translated
  language: string@language-completer-1 # Translation language
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TranslateString"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}, {name: language, var: language}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input, language: $language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Trim string
#
# POST /TrimString
# Returns: record<result: string>
# operationId: TrimString
export def "trim-string" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # String containing the text to be trimmed
  type: string@type-completer-3 # Type of white space to remove
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TrimString"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Decode URL
#
# POST /URLDecode
# Returns: record<result: string>
# operationId: UrlDecode
export def "url-decode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # Encoded string variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/URLDecode"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Encode URL
#
# POST /URLEncode
# Returns: record<result: string>
# operationId: UrlEncode
export def "url-encode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # String variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/URLEncode"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Validate email
#
# POST /ValidateEmail
# Returns: record<result: string>
# operationId: ValidateEmail
export def "validate-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  source: string # String variable or text value
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ValidateEmail"
    body: {content_type: "application/json", kind: json, fields: [{name: source, var: source}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Text - Verify hash
#
# POST /VerifyHash
# Returns: record<result: bool>
# operationId: VerifyHash
export def "verify-hash" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  algorithm: string@algorithm-completer # Hash algorithm
  hash: string # Hashed result
  input: string # Original source string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/VerifyHash"
    body: {content_type: "application/json", kind: json, fields: [{name: algorithm, var: algorithm}, {name: hash, var: hash}, {name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    algorithm: $algorithm, hash: $hash, input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Files - Watermark Image
#
# POST /WatermarkImage
# Returns: binary
# operationId: WatermarkImage
export def "watermark-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  color: string # Text color hex value (default: 000000)
  file: string # Source image file (format: binary)
  font: string@font-completer # Text font (default: Arial)
  horizontal: string@horizontal-completer # Horizontal alignment (default: Center)
  size: float # Font size (points)
  text: string # Watermark text
  vertical: string@vertical-completer # Vertical alignment (default: Center)
]: any -> any {
  $in | http-request {
    method: post
    path: "/WatermarkImage"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: color, var: color}, {name: file, var: file}, {name: font, var: font}, {name: horizontal, var: horizontal}, {name: size, var: size}, {name: text, var: text}, {name: vertical, var: vertical}], files: [file]}
    accept: ["*/*"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    color: $color, file: $file, font: $font, horizontal: $horizontal, size: $size, text: $text, vertical: $vertical
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DateTime - Get world time
#
# POST /WorldTime
# Returns: record<result: string>
# operationId: WorldTime
export def "world-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Display format (defaults to 'yyyy-MM-dd HH:mm:ss')
  input: string # Source date and time
  source: string@source-completer-11 # default: GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London
  target: string@target-completer-11 # default: GMT Standard Time - (GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/WorldTime"
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}, {name: input, var: input}, {name: source, var: source}, {name: target, var: target}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    format: $format, input: $input, source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Data - XML to JSON
#
# POST /XMLtoJSON
# Returns: record<result: string>
# operationId: XmlToJson
export def "xml-to-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  input: string # XML string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/XMLtoJSON"
    body: {content_type: "application/json", kind: json, fields: [{name: input, var: input}]}
    accept: ["application/json"]
    ok: [200]
    auth: x-ibm-client-id
  } {
    input: $input
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
