# Auto-generated client for WebSite Management Client v2015-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/web-service/2015-08-01/swagger.json
# Auth: --token flag or $env.WEBSITE_MANAGEMENT_CLIENT_TOKEN

const CLIENT = {
  base_url: "https://management.azure.com"
  token_env_var: "WEBSITE_MANAGEMENT_CLIENT_TOKEN"
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
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def default-provider-completer [] { ["AzureActiveDirectory" "Facebook" "Google" "MicrosoftAccount" "Twitter"] }
def unauthenticated-client-action-completer [] { ["AllowAnonymous" "RedirectToLoginPage"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    provider-get-publishing-user: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    provider-update-publishing-user: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    provider-get-source-controls: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    provider-get-source-control: "record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    provider-update-source-control: "record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    global-certificate-order-get-all-certificate-orders: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-certificate-order-validate-certificate-purchase-information: "record"
    global-domain-registration-check-domain-availability: "record<available: bool, domainType: string, name: string>"
    global-domain-registration-get-all-domains: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-domain-registration-get-domain-control-center-sso-request: "record<postParameterKey: string, postParameterValue: string, url: string>"
    global-domain-registration-list-domain-recommendations: "record<nextLink: string, value: table<name: string>>"
    top-level-domains-get-get-top-level-domains: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    top-level-domains-get-top-level-domain: "record<properties: record<name: string, privacy: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    top-level-domains-list-top-level-domain-agreements: "record<nextLink: string, value: table<agreementKey: string, content: string, title: string, url: string>>"
    global-domain-registration-validate-domain-purchase-information: "record"
    global-get-all-certificates: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-check-name-availability: "record<message: string, nameAvailable: bool, reason: string>"
    global-get-all-classic-mobile-services: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-get-subscription-geo-regions: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-get-all-hosting-environments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-is-hosting-environment-name-available: "record"
    global-is-hosting-environment-with-legacy-name-available: "record"
    global-get-all-managed-hosting-environments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-list-premier-add-on-offers: "record"
    global-get-subscription-publishing-credentials: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    global-update-subscription-publishing-credentials: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    recommendations-get-recommendation-by-subscription: "table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>"
    global-get-all-server-farms: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    global-get-all-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    certificate-orders-get-certificate-orders: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    certificate-orders-get-certificates: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    certificate-orders-delete-certificate: "record"
    certificate-orders-get-certificate: "record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-update-certificate: "record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-create-or-update-certificate: "record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-delete-certificate-order: "record"
    certificate-orders-get-certificate-order: "record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-update-certificate-order: "record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-create-or-update-certificate-order: "record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-reissue-certificate-order: "record"
    certificate-orders-renew-certificate-order: "record"
    certificate-orders-resend-certificate-email: "record"
    certificate-orders-retrieve-certificate-actions: "table<properties: record<createdAt: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-retrieve-certificate-email-history: "table<properties: record<emailId: string, timeStamp: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificate-orders-verify-domain-ownership: "record"
    domains-get-domains: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    domains-delete-domain: "record"
    domains-get-domain: "record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    domains-update-domain: "record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    domains-create-or-update-domain: "record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    domains-get-domain-operation: "record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    usage-get-usage: "record"
    certificates-get-certificates: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    certificates-delete-certificate: "record"
    certificates-get-certificate: "record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-update-certificate: "record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-create-or-update-certificate: "record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    classic-mobile-services-get-classic-mobile-services: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    classic-mobile-services-delete-classic-mobile-service: "record"
    classic-mobile-services-get-classic-mobile-service: "record<properties: record<name: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-get-csrs: "table<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-delete-csr: "record"
    certificates-get-csr: "record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-update-csr: "record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    certificates-create-or-update-csr: "record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-deleted-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-delete-hosting-environment: "record"
    hosting-environments-get-hosting-environment: "record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-create-or-update-hosting-environment: "record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-get-hosting-environment-capacities: "record<nextLink: string, value: table<availableCapacity: int, computeMode: string, excludeFromCapacityAllocation: bool, isApplicableForAllComputeModes: bool, name: string, siteMode: string, totalCapacity: int, unit: string, workerSize: string, workerSizeId: int>>"
    hosting-environments-get-hosting-environment-vips: "record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>>"
    hosting-environments-get-hosting-environment-diagnostics: "table<diagnosicsOutput: string, name: string>"
    hosting-environments-get-hosting-environment-diagnostics-item: "record<diagnosicsOutput: string, name: string>"
    hosting-environments-get-hosting-environment-metric-definitions: "record<properties: record<displayName: string, metricAvailabilities: list<record>, name: string, primaryAggregationType: string, unit: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-get-hosting-environment-metrics: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    hosting-environments-get-multi-role-pools: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-multi-role-pool: "record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-create-or-update-multi-role-pool: "record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-get-multi-role-pool-instance-metric-definitions: "record"
    hosting-environments-get-multi-role-pool-instance-metrics: "record"
    hosting-environments-get-hosting-environment-multi-role-metric-definitions: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-multi-role-metrics: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    hosting-environments-get-multi-role-pool-skus: "record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>"
    hosting-environments-get-hosting-environment-multi-role-usages: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-operations: "record"
    hosting-environments-get-hosting-environment-operation: "record"
    hosting-environments-reboot-hosting-environment: "record"
    hosting-environments-resume-hosting-environment: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-server-farms: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-suspend-hosting-environment: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-usages: "record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>"
    hosting-environments-get-hosting-environment-web-hosting-plans: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-worker-pools: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-worker-pool: "record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-create-or-update-worker-pool: "record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    hosting-environments-get-worker-pool-instance-metric-definitions: "record"
    hosting-environments-get-worker-pool-instance-metrics: "record"
    hosting-environments-get-hosting-environment-web-worker-metric-definitions: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    hosting-environments-get-hosting-environment-web-worker-metrics: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    hosting-environments-get-worker-pool-skus: "record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>"
    hosting-environments-get-hosting-environment-web-worker-usages: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    managed-hosting-environments-get-managed-hosting-environments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    managed-hosting-environments-delete-managed-hosting-environment: "record"
    managed-hosting-environments-get-managed-hosting-environment: "record<properties: record<apiManagementAccount: string, dnsSuffix: string, environmentIsHealthy: bool, environmentStatus: string, ipsslAddressCount: int, location: string, name: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, virtualNetwork: record<id: string, name: string, subnet: string, type: string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    managed-hosting-environments-create-or-update-managed-hosting-environment: "record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    managed-hosting-environments-get-managed-hosting-environment-vips: "record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>>"
    managed-hosting-environments-get-managed-hosting-environment-operation: "record"
    managed-hosting-environments-get-managed-hosting-environment-server-farms: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    managed-hosting-environments-get-managed-hosting-environment-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    managed-hosting-environments-get-managed-hosting-environment-web-hosting-plans: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    server-farms-get-server-farms: "record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    server-farms-delete-server-farm: "record"
    server-farms-get-server-farm: "record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-create-or-update-server-farm: "record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-get-server-farm-metric-defintions: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    server-farms-get-server-farm-metrics: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    server-farms-get-server-farm-operation: "record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-restart-sites-for-server-farm: "record"
    server-farms-get-server-farm-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    server-farms-get-vnets-for-server-farm: "table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-get-vnet-from-server-farm: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-get-server-farm-vnet-gateway: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-update-server-farm-vnet-gateway: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-get-routes-for-vnet: "table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-delete-vnet-route: "record"
    server-farms-get-route-for-vnet: "table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-update-vnet-route: "record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-create-or-update-vnet-route: "record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    server-farms-reboot-worker-for-server-farm: "record"
    sites-get-sites: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-site: "record"
    sites-get-site: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-apply-slot-config-to-production: "record"
    sites-backup-site: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-backups: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-discover-site-restore: "record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-backup: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-status: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-status-secrets: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-restore-site: "record<properties: record<operationId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-app-settings: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-app-settings: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-auth-settings: "record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>"
    sites-list-site-auth-settings: "record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>"
    sites-update-site-backup-configuration: "record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-configuration: "record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-connection-strings: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-connection-strings: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-logs-config: "record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-logs-config: "record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-metadata: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-metadata: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-publishing-credentials: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-slot-config-names: "record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-slot-config-names: "record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-config: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-config: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-config: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-deployments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-deployment: "record"
    sites-get-deployment: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-deployment: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-host-name-bindings: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-site-host-name-binding: "record"
    sites-get-site-host-name-binding: "record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-host-name-binding: "record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-relay-service-connections: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-site-relay-service-connection: "record"
    sites-get-site-relay-service-connection: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-relay-service-connection: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-relay-service-connection: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-instance-identifiers: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-get-instance-deployments: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-instance-deployment: "record"
    sites-get-instance-deployment: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-instance-deployment: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-is-site-cloneable: "record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>>"
    sites-get-site-metric-definitions: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-get-site-metrics: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    sites-get-site-network-features: "record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, virtualNetworkName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-generate-new-site-publishing-password: "record"
    sites-get-site-operation: "record"
    sites-list-site-premier-add-ons: "record"
    sites-delete-site-premier-add-on: "record"
    sites-get-site-premier-add-on: "record"
    sites-add-site-premier-add-on: "record"
    sites-list-site-publishing-profile-xml: "binary"
    sites-recover-site: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-reset-production-slot-config: "record"
    sites-restart-site: "record"
    sites-get-site-slots: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-site-slot: "record"
    sites-get-site-slot: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-slot: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-apply-slot-config-slot: "record"
    sites-backup-site-slot: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-backups-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-discover-site-restore-slot: "record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-backup-slot: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-status-slot: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-status-secrets-slot: "record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-restore-site-slot: "record<properties: record<operationId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-app-settings-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-app-settings-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-auth-settings-slot: "record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>"
    sites-list-site-auth-settings-slot: "record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>"
    sites-update-site-backup-configuration-slot: "record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-backup-configuration-slot: "record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-connection-strings-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-connection-strings-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-logs-config-slot: "record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-logs-config-slot: "record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-metadata-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-metadata-slot: "record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-publishing-credentials-slot: "record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-config-slot: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-config-slot: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-config-slot: "record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-deployments-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-deployment-slot: "record"
    sites-get-deployment-slot: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-deployment-slot: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-host-name-bindings-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-site-host-name-binding-slot: "record"
    sites-get-site-host-name-binding-slot: "record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-host-name-binding-slot: "record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-list-site-relay-service-connections-slot: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-site-relay-service-connection-slot: "record"
    sites-get-site-relay-service-connection-slot: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-relay-service-connection-slot: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-relay-service-connection-slot: "record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-instance-identifiers-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-get-instance-deployments-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-delete-instance-deployment-slot: "record"
    sites-get-instance-deployment-slot: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-instance-deployment-slot: "record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-is-site-cloneable-slot: "record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>>"
    sites-get-site-metric-definitions-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-get-site-metrics-slot: "record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>"
    sites-get-site-network-features-slot: "record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, virtualNetworkName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-generate-new-site-publishing-password-slot: "record"
    sites-get-site-operation-slot: "record"
    sites-list-site-premier-add-ons-slot: "record"
    sites-delete-site-premier-add-on-slot: "record"
    sites-get-site-premier-add-on-slot: "record"
    sites-add-site-premier-add-on-slot: "record"
    sites-list-site-publishing-profile-xml-slot: "binary"
    sites-recover-site-slot: "record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-reset-slot-config-slot: "record"
    sites-restart-site-slot: "record"
    sites-get-slots-differences-slot: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-swap-slots-slot: "record"
    sites-get-site-snapshots-slot: "record"
    sites-delete-site-source-control-slot: "record"
    sites-get-site-source-control-slot: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-source-control-slot: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-source-control-slot: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-start-site-slot: "record"
    sites-stop-site-slot: "record"
    sites-sync-site-repository-slot: "record"
    sites-get-site-usages-slot: "record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>"
    sites-get-site-vnet-connections-slot: "table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-site-vnet-connection-slot: "record"
    sites-get-site-vnet-connection-slot: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-vnet-connection-slot: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-vnet-connection-slot: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-vnet-gateway-slot: "record"
    sites-update-site-vnet-connection-gateway-slot: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-vnet-connection-gateway-slot: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-slots-differences-from-production: "record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>"
    sites-swap-slot-with-production: "record"
    sites-get-site-snapshots: "record"
    sites-delete-site-source-control: "record"
    sites-get-site-source-control: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-source-control: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-source-control: "record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-start-site: "record"
    sites-stop-site: "record"
    sites-sync-site-repository: "record"
    sites-get-site-usages: "record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>"
    sites-get-site-vnet-connections: "table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-delete-site-vnet-connection: "record"
    sites-get-site-vnet-connection: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-update-site-vnet-connection: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-vnet-connection: "record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-get-site-vnet-gateway: "record"
    sites-update-site-vnet-connection-gateway: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    sites-create-or-update-site-vnet-connection-gateway: "record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>"
    recommendations-get-recommendation-history-for-site: "table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>"
    recommendations-get-recommended-rules-for-site: "table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>"
    recommendations-get-rule-details-by-site-name: "record<actionName: string, channels: string, description: string, displayName: string, enabled: int, level: string, message: string, name: string, recommendationId: string, tags: list<string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["provider-get-publishing-user" "provider-update-publishing-user" "provider-get-source-controls" "provider-get-source-control" "provider-update-source-control" "global-certificate-order-get-all-certificate-orders" "global-certificate-order-validate-certificate-purchase-information" "global-domain-registration-check-domain-availability" "global-domain-registration-get-all-domains" "global-domain-registration-get-domain-control-center-sso-request" "global-domain-registration-list-domain-recommendations" "top-level-domains-get-get-top-level-domains" "top-level-domains-get-top-level-domain" "top-level-domains-list-top-level-domain-agreements" "global-domain-registration-validate-domain-purchase-information" "global-get-all-certificates" "global-check-name-availability" "global-get-all-classic-mobile-services" "global-get-subscription-geo-regions" "global-get-all-hosting-environments" "global-is-hosting-environment-name-available" "global-is-hosting-environment-with-legacy-name-available" "global-get-all-managed-hosting-environments" "global-list-premier-add-on-offers" "global-get-subscription-publishing-credentials" "global-update-subscription-publishing-credentials" "recommendations-get-recommendation-by-subscription" "global-get-all-server-farms" "global-get-all-sites" "global-resource-groups-move-resources" "certificate-orders-get-certificate-orders" "certificate-orders-get-certificates" "certificate-orders-delete-certificate" "certificate-orders-get-certificate" "certificate-orders-update-certificate" "certificate-orders-create-or-update-certificate" "certificate-orders-delete-certificate-order" "certificate-orders-get-certificate-order" "certificate-orders-update-certificate-order" "certificate-orders-create-or-update-certificate-order" "certificate-orders-reissue-certificate-order" "certificate-orders-renew-certificate-order" "certificate-orders-resend-certificate-email" "certificate-orders-retrieve-certificate-actions" "certificate-orders-retrieve-certificate-email-history" "certificate-orders-verify-domain-ownership" "domains-get-domains" "domains-delete-domain" "domains-get-domain" "domains-update-domain" "domains-create-or-update-domain" "domains-get-domain-operation" "usage-get-usage" "certificates-get-certificates" "certificates-delete-certificate" "certificates-get-certificate" "certificates-update-certificate" "certificates-create-or-update-certificate" "classic-mobile-services-get-classic-mobile-services" "classic-mobile-services-delete-classic-mobile-service" "classic-mobile-services-get-classic-mobile-service" "certificates-get-csrs" "certificates-delete-csr" "certificates-get-csr" "certificates-update-csr" "certificates-create-or-update-csr" "sites-get-deleted-sites" "hosting-environments-get-hosting-environments" "hosting-environments-delete-hosting-environment" "hosting-environments-get-hosting-environment" "hosting-environments-create-or-update-hosting-environment" "hosting-environments-get-hosting-environment-capacities" "hosting-environments-get-hosting-environment-vips" "hosting-environments-get-hosting-environment-diagnostics" "hosting-environments-get-hosting-environment-diagnostics-item" "hosting-environments-get-hosting-environment-metric-definitions" "hosting-environments-get-hosting-environment-metrics" "hosting-environments-get-multi-role-pools" "hosting-environments-get-multi-role-pool" "hosting-environments-create-or-update-multi-role-pool" "hosting-environments-get-multi-role-pool-instance-metric-definitions" "hosting-environments-get-multi-role-pool-instance-metrics" "hosting-environments-get-hosting-environment-multi-role-metric-definitions" "hosting-environments-get-hosting-environment-multi-role-metrics" "hosting-environments-get-multi-role-pool-skus" "hosting-environments-get-hosting-environment-multi-role-usages" "hosting-environments-get-hosting-environment-operations" "hosting-environments-get-hosting-environment-operation" "hosting-environments-reboot-hosting-environment" "hosting-environments-resume-hosting-environment" "hosting-environments-get-hosting-environment-server-farms" "hosting-environments-get-hosting-environment-sites" "hosting-environments-suspend-hosting-environment" "hosting-environments-get-hosting-environment-usages" "hosting-environments-get-hosting-environment-web-hosting-plans" "hosting-environments-get-worker-pools" "hosting-environments-get-worker-pool" "hosting-environments-create-or-update-worker-pool" "hosting-environments-get-worker-pool-instance-metric-definitions" "hosting-environments-get-worker-pool-instance-metrics" "hosting-environments-get-hosting-environment-web-worker-metric-definitions" "hosting-environments-get-hosting-environment-web-worker-metrics" "hosting-environments-get-worker-pool-skus" "hosting-environments-get-hosting-environment-web-worker-usages" "managed-hosting-environments-get-managed-hosting-environments" "managed-hosting-environments-delete-managed-hosting-environment" "managed-hosting-environments-get-managed-hosting-environment" "managed-hosting-environments-create-or-update-managed-hosting-environment" "managed-hosting-environments-get-managed-hosting-environment-vips" "managed-hosting-environments-get-managed-hosting-environment-operation" "managed-hosting-environments-get-managed-hosting-environment-server-farms" "managed-hosting-environments-get-managed-hosting-environment-sites" "managed-hosting-environments-get-managed-hosting-environment-web-hosting-plans" "server-farms-get-server-farms" "server-farms-delete-server-farm" "server-farms-get-server-farm" "server-farms-create-or-update-server-farm" "server-farms-get-server-farm-metric-defintions" "server-farms-get-server-farm-metrics" "server-farms-get-server-farm-operation" "server-farms-restart-sites-for-server-farm" "server-farms-get-server-farm-sites" "server-farms-get-vnets-for-server-farm" "server-farms-get-vnet-from-server-farm" "server-farms-get-server-farm-vnet-gateway" "server-farms-update-server-farm-vnet-gateway" "server-farms-get-routes-for-vnet" "server-farms-delete-vnet-route" "server-farms-get-route-for-vnet" "server-farms-update-vnet-route" "server-farms-create-or-update-vnet-route" "server-farms-reboot-worker-for-server-farm" "sites-get-sites" "sites-delete-site" "sites-get-site" "sites-create-or-update-site" "sites-apply-slot-config-to-production" "sites-backup-site" "sites-list-site-backups" "sites-discover-site-restore" "sites-delete-backup" "sites-get-site-backup-status" "sites-get-site-backup-status-secrets" "sites-restore-site" "sites-update-site-app-settings" "sites-list-site-app-settings" "sites-update-site-auth-settings" "sites-list-site-auth-settings" "sites-update-site-backup-configuration" "sites-get-site-backup-configuration" "sites-update-site-connection-strings" "sites-list-site-connection-strings" "sites-get-site-logs-config" "sites-update-site-logs-config" "sites-update-site-metadata" "sites-list-site-metadata" "sites-list-site-publishing-credentials" "sites-get-slot-config-names" "sites-update-slot-config-names" "sites-get-site-config" "sites-update-site-config" "sites-create-or-update-site-config" "sites-get-deployments" "sites-delete-deployment" "sites-get-deployment" "sites-create-deployment" "sites-get-site-host-name-bindings" "sites-delete-site-host-name-binding" "sites-get-site-host-name-binding" "sites-create-or-update-site-host-name-binding" "sites-list-site-relay-service-connections" "sites-delete-site-relay-service-connection" "sites-get-site-relay-service-connection" "sites-update-site-relay-service-connection" "sites-create-or-update-site-relay-service-connection" "sites-get-site-instance-identifiers" "sites-get-instance-deployments" "sites-delete-instance-deployment" "sites-get-instance-deployment" "sites-create-instance-deployment" "sites-is-site-cloneable" "sites-get-site-metric-definitions" "sites-get-site-metrics" "sites-get-site-network-features" "sites-generate-new-site-publishing-password" "sites-get-site-operation" "sites-list-site-premier-add-ons" "sites-delete-site-premier-add-on" "sites-get-site-premier-add-on" "sites-add-site-premier-add-on" "sites-list-site-publishing-profile-xml" "sites-recover-site" "sites-reset-production-slot-config" "sites-restart-site" "sites-get-site-slots" "sites-delete-site-slot" "sites-get-site-slot" "sites-create-or-update-site-slot" "sites-apply-slot-config-slot" "sites-backup-site-slot" "sites-list-site-backups-slot" "sites-discover-site-restore-slot" "sites-delete-backup-slot" "sites-get-site-backup-status-slot" "sites-get-site-backup-status-secrets-slot" "sites-restore-site-slot" "sites-update-site-app-settings-slot" "sites-list-site-app-settings-slot" "sites-update-site-auth-settings-slot" "sites-list-site-auth-settings-slot" "sites-update-site-backup-configuration-slot" "sites-get-site-backup-configuration-slot" "sites-update-site-connection-strings-slot" "sites-list-site-connection-strings-slot" "sites-get-site-logs-config-slot" "sites-update-site-logs-config-slot" "sites-update-site-metadata-slot" "sites-list-site-metadata-slot" "sites-list-site-publishing-credentials-slot" "sites-get-site-config-slot" "sites-update-site-config-slot" "sites-create-or-update-site-config-slot" "sites-get-deployments-slot" "sites-delete-deployment-slot" "sites-get-deployment-slot" "sites-create-deployment-slot" "sites-get-site-host-name-bindings-slot" "sites-delete-site-host-name-binding-slot" "sites-get-site-host-name-binding-slot" "sites-create-or-update-site-host-name-binding-slot" "sites-list-site-relay-service-connections-slot" "sites-delete-site-relay-service-connection-slot" "sites-get-site-relay-service-connection-slot" "sites-update-site-relay-service-connection-slot" "sites-create-or-update-site-relay-service-connection-slot" "sites-get-site-instance-identifiers-slot" "sites-get-instance-deployments-slot" "sites-delete-instance-deployment-slot" "sites-get-instance-deployment-slot" "sites-create-instance-deployment-slot" "sites-is-site-cloneable-slot" "sites-get-site-metric-definitions-slot" "sites-get-site-metrics-slot" "sites-get-site-network-features-slot" "sites-generate-new-site-publishing-password-slot" "sites-get-site-operation-slot" "sites-list-site-premier-add-ons-slot" "sites-delete-site-premier-add-on-slot" "sites-get-site-premier-add-on-slot" "sites-add-site-premier-add-on-slot" "sites-list-site-publishing-profile-xml-slot" "sites-recover-site-slot" "sites-reset-slot-config-slot" "sites-restart-site-slot" "sites-get-slots-differences-slot" "sites-swap-slots-slot" "sites-get-site-snapshots-slot" "sites-delete-site-source-control-slot" "sites-get-site-source-control-slot" "sites-update-site-source-control-slot" "sites-create-or-update-site-source-control-slot" "sites-start-site-slot" "sites-stop-site-slot" "sites-sync-site-repository-slot" "sites-get-site-usages-slot" "sites-get-site-vnet-connections-slot" "sites-delete-site-vnet-connection-slot" "sites-get-site-vnet-connection-slot" "sites-update-site-vnet-connection-slot" "sites-create-or-update-site-vnet-connection-slot" "sites-get-site-vnet-gateway-slot" "sites-update-site-vnet-connection-gateway-slot" "sites-create-or-update-site-vnet-connection-gateway-slot" "sites-get-slots-differences-from-production" "sites-swap-slot-with-production" "sites-get-site-snapshots" "sites-delete-site-source-control" "sites-get-site-source-control" "sites-update-site-source-control" "sites-create-or-update-site-source-control" "sites-start-site" "sites-stop-site" "sites-sync-site-repository" "sites-get-site-usages" "sites-get-site-vnet-connections" "sites-delete-site-vnet-connection" "sites-get-site-vnet-connection" "sites-update-site-vnet-connection" "sites-create-or-update-site-vnet-connection" "sites-get-site-vnet-gateway" "sites-update-site-vnet-connection-gateway" "sites-create-or-update-site-vnet-connection-gateway" "recommendations-get-recommendation-history-for-site" "recommendations-get-recommended-rules-for-site" "recommendations-get-rule-details-by-site-name" "commands"] | sort) } | get name | first)
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

# Gets publishing user
#
# GET /providers/Microsoft.Web/publishingUsers/web
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Provider_GetPublishingUser
export def "provider-get-publishing-user" [
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Web/publishingUsers/web"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates publishing user
#
# PUT /providers/Microsoft.Web/publishingUsers/web
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Provider_UpdatePublishingUser
export def "provider-update-publishing-user" [
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
  --api-version: string # API Version (required)
  --properties: any # shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Web/publishingUsers/web"
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the source controls available for Azure websites
#
# GET /providers/Microsoft.Web/sourcecontrols
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Provider_GetSourceControls
export def "provider-get-source-controls" [
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Web/sourcecontrols"
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets source control token
#
# GET /providers/Microsoft.Web/sourcecontrols/{sourceControlType}
# Returns: record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Provider_GetSourceControl
export def "provider-get-source-control" [
  source_control_type: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/Microsoft.Web/sourcecontrols/{sourceControlType}"
    path_params: [{name: sourceControlType, var: source_control_type}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_control_type: $source_control_type, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates source control token
#
# PUT /providers/Microsoft.Web/sourcecontrols/{sourceControlType}
# Returns: record<properties: record<expirationTime: string, name: string, refreshToken: string, token: string, tokenSecret: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Provider_UpdateSourceControl
export def "provider-update-source-control" [
  source_control_type: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {expirationTime?: string, name?: string, refreshToken?: string, token?: string, tokenSecret?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providers/Microsoft.Web/sourcecontrols/{sourceControlType}"
    path_params: [{name: sourceControlType, var: source_control_type}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    source_control_type: $source_control_type, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all domains in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/certificateOrders
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: GlobalCertificateOrder_GetAllCertificateOrders
export def "global-certificate-order-get-all-certificate-orders" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/certificateOrders"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate certificate purchase information
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/validateCertificateRegistrationInformation
# Returns: record
# operationId: GlobalCertificateOrder_ValidateCertificatePurchaseInformation
export def "global-certificate-order-validate-certificate-purchase-information" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.CertificateRegistration/validateCertificateRegistrationInformation"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks if a domain is available for registration
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/checkDomainAvailability
# Returns: record<available: bool, domainType: string, name: string>
# operationId: GlobalDomainRegistration_CheckDomainAvailability
export def "global-domain-registration-check-domain-availability" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --name: string # Name of the object
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/checkDomainAvailability"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all domains in a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/domains
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: GlobalDomainRegistration_GetAllDomains
export def "global-domain-registration-get-all-domains" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/domains"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generates a single sign on request for domain management portal
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/generateSsoRequest
# Returns: record<postParameterKey: string, postParameterValue: string, url: string>
# operationId: GlobalDomainRegistration_GetDomainControlCenterSsoRequest
export def "global-domain-registration-get-domain-control-center-sso-request" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/generateSsoRequest"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists domain recommendations based on keywords
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/listDomainRecommendations
# Returns: record<nextLink: string, value: table<name: string>>
# operationId: GlobalDomainRegistration_ListDomainRecommendations
export def "global-domain-registration-list-domain-recommendations" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
  --keywords: string # Keywords to be used for generating domain recommendations
  --max-domain-recommendations: int # Maximum number of recommendations (format: int32)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/listDomainRecommendations"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: keywords, var: keywords}, {name: maxDomainRecommendations, var: max_domain_recommendations}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, keywords: $keywords, max_domain_recommendations: $max_domain_recommendations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all top level domains supported for registration
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: TopLevelDomains_GetGetTopLevelDomains
export def "top-level-domains-get-get-top-level-domains" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets details of a top level domain
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}
# Returns: record<properties: record<name: string, privacy: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: TopLevelDomains_GetTopLevelDomain
export def "top-level-domains-get-top-level-domain" [
  subscription_id: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists legal agreements that user needs to accept before purchasing domain
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}/listAgreements
# Returns: record<nextLink: string, value: table<agreementKey: string, content: string, title: string, url: string>>
# operationId: TopLevelDomains_ListTopLevelDomainAgreements
export def "top-level-domains-list-top-level-domain-agreements" [
  subscription_id: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
  --include-privacy: oneof<nothing, bool> # If true then the list of agreements will include agreements for domain privacy as well.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/topLevelDomains/{name}/listAgreements"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: includePrivacy, var: include_privacy}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, name: $name, api_version: $api_version, include_privacy: $include_privacy
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validates domain registration information
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/validateDomainRegistrationInformation
# Returns: record
# operationId: GlobalDomainRegistration_ValidateDomainPurchaseInformation
export def "global-domain-registration-validate-domain-purchase-information" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, name?: string, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.DomainRegistration/validateDomainRegistrationInformation"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all certificates for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/certificates
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllCertificates
export def "global-get-all-certificates" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check if resource name is available
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Web/checknameavailability
# Returns: record<message: string, nameAvailable: bool, reason: string>
# operationId: Global_CheckNameAvailability
export def "global-check-name-availability" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --is-fqdn: oneof<nothing, bool> # Is fully qualified domain name
  --name: string # Resource name to verify
  --type: string # Resource type used for verification
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/checknameavailability"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: isFqdn, var: is_fqdn}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, is_fqdn: $is_fqdn, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all mobile services for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/classicMobileServices
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllClassicMobileServices
export def "global-get-all-classic-mobile-services" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/classicMobileServices"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of available geo regions
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/geoRegions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetSubscriptionGeoRegions
export def "global-get-subscription-geo-regions" [
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
  --accept: string@accept-completer-1 # Response content type
  --sku: string # Filter only to regions that support this sku
  --linux-workers-enabled: oneof<nothing, bool> # Filter only to regions that support linux workers
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/geoRegions"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: sku, var: sku}, {name: linuxWorkersEnabled, var: linux_workers_enabled}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, sku: $sku, linux_workers_enabled: $linux_workers_enabled, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all hostingEnvironments (App Service Environment) for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/hostingEnvironments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllHostingEnvironments
export def "global-get-all-hosting-environments" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/hostingEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Whether hosting environment name is available
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable
# Returns: record
# operationId: Global_IsHostingEnvironmentNameAvailable
export def "global-is-hosting-environment-name-available" [
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
  --accept: string@accept-completer # Response content type
  --name: string # Hosting environment name (required)
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: name, var: name, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Whether hosting environment name is available
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable/{name}
# Returns: record
# operationId: Global_IsHostingEnvironmentWithLegacyNameAvailable
export def "global-is-hosting-environment-with-legacy-name-available" [
  subscription_id: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/ishostingenvironmentnameavailable/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all managed hosting environments for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/managedHostingEnvironments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllManagedHostingEnvironments
export def "global-get-all-managed-hosting-environments" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/managedHostingEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List premier add on offers
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/premieraddonoffers
# Returns: record
# operationId: Global_ListPremierAddOnOffers
export def "global-list-premier-add-on-offers" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/premieraddonoffers"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets publishing credentials for the subscription owner
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Global_GetSubscriptionPublishingCredentials
export def "global-get-subscription-publishing-credentials" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates publishing credentials for the subscription owner
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Global_UpdateSubscriptionPublishingCredentials
export def "global-update-subscription-publishing-credentials" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {name?: string, publishingPassword?: string, publishingUserName?: string, scmUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/publishingCredentials"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of recommendations associated with the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/recommendations
# Returns: table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>
# operationId: Recommendations_GetRecommendationBySubscription
export def "recommendations-get-recommendation-by-subscription" [
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
  --accept: string@accept-completer # Response content type
  --featured: oneof<nothing, bool> # If set, this API returns only the most critical recommendation among the others. Otherwise this API returns all recommendations available
  --filter: string # Return only channels specified in the filter. Filter is specified by using OData syntax. Example: $filter=channels eq 'Api' or channel eq 'Notification'
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/recommendations"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: featured, var: featured}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, featured: $featured, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all App Service Plans for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/serverfarms
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllServerFarms
export def "global-get-all-server-farms" [
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
  --accept: string@accept-completer-1 # Response content type
  --detailed: oneof<nothing, bool> # False to return a subset of App Service Plan properties, true to return all of the properties. Retrieval of all properties may increase the API latency.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/serverfarms"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: detailed, var: detailed}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, detailed: $detailed, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Web Apps for a subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Web/sites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Global_GetAllSites
export def "global-get-all-sites" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/providers/Microsoft.Web/sites"
    path_params: [{name: subscriptionId, var: subscription_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/moveResources
#
# operationId: GlobalResourceGroups_MoveResources
export def "global-resource-groups-move-resources" [
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
  --api-version: string # API Version (required)
  --resources: list<string>
  --target-resource-group: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/moveResources"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: resources, var: resources}, {name: targetResourceGroup, var: target_resource_group}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version, resources: $resources, target_resource_group: $target_resource_group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get certificate orders in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: CertificateOrders_GetCertificateOrders
export def "certificate-orders-get-certificate-orders" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all certificates associated with a certificate order (only one certificate can be associated with an order at a time)
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: CertificateOrders_GetCertificates
export def "certificate-orders-get-certificates" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: certificateOrderName, var: certificate_order_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, certificate_order_name: $certificate_order_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes the certificate associated with the certificate order
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# Returns: record
# operationId: CertificateOrders_DeleteCertificate
export def "certificate-orders-delete-certificate" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: certificateOrderName, var: certificate_order_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, certificate_order_name: $certificate_order_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get certificate associated with the certificate order
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# Returns: record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_GetCertificate
export def "certificate-orders-get-certificate" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: certificateOrderName, var: certificate_order_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, certificate_order_name: $certificate_order_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Associates a Key Vault secret to a certificate store that will be used for storing the certificate once it's ready
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# Returns: record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_UpdateCertificate
export def "certificate-orders-update-certificate" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: certificateOrderName, var: certificate_order_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, certificate_order_name: $certificate_order_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Associates a Key Vault secret to a certificate store that will be used for storing the certificate once it's ready
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}
# Returns: record<properties: record<keyVaultId: string, keyVaultSecretName: string, provisioningState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_CreateOrUpdateCertificate
export def "certificate-orders-create-or-update-certificate" [
  subscription_id: string
  resource_group_name: string
  certificate_order_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {keyVaultId?: string, keyVaultSecretName?: string, provisioningState?: "Initialized"|"WaitingOnCertificateOrder"|"Succeeded"|"CertificateOrderFailed"|"OperationNotPermittedOnKeyVault"|"AzureServiceUnauthorizedToAccessKeyVault"|"KeyVaultDoesNotExist"|"KeyVaultSecretDoesNotExist"|"UnknownError"|"Unknown"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{certificateOrderName}/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: certificateOrderName, var: certificate_order_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, certificate_order_name: $certificate_order_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete an existing certificate order
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# Returns: record
# operationId: CertificateOrders_DeleteCertificateOrder
export def "certificate-orders-delete-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a certificate order
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# Returns: record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_GetCertificateOrder
export def "certificate-orders-get-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a certificate purchase order
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# Returns: record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_UpdateCertificateOrder
export def "certificate-orders-update-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a certificate purchase order
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}
# Returns: record<properties: record<autoRenew: bool, certificates: record, csr: string, distinguishedName: string, domainVerificationToken: string, expirationTime: string, intermediate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, keySize: int, lastCertificateIssuanceTime: string, productType: string, provisioningState: string, root: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, serialNumber: string, signedCertificate: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, status: string, validityInYears: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_CreateOrUpdateCertificateOrder
export def "certificate-orders-create-or-update-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, certificates?: record, csr?: string, distinguishedName?: string, domainVerificationToken?: string, expirationTime?: string, intermediate?: record, keySize?: int, lastCertificateIssuanceTime?: string, productType?: "StandardDomainValidatedSsl"|"StandardDomainValidatedWildCardSsl", provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", root?: record, serialNumber?: string, signedCertificate?: record, ... (2 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Reissue an existing certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/reissue
# Returns: record
# operationId: CertificateOrders_ReissueCertificateOrder
export def "certificate-orders-reissue-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {delayExistingRevokeInHours?: int, keySize?: int}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/reissue"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Renew an existing certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/renew
# Returns: record
# operationId: CertificateOrders_RenewCertificateOrder
export def "certificate-orders-renew-certificate-order" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {keySize?: int}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/renew"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resend certificate email
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/resendEmail
# Returns: record
# operationId: CertificateOrders_ResendCertificateEmail
export def "certificate-orders-resend-certificate-email" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/resendEmail"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the list of certificate actions
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveCertificateActions
# Returns: table<properties: record<createdAt: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_RetrieveCertificateActions
export def "certificate-orders-retrieve-certificate-actions" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveCertificateActions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve email history
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveEmailHistory
# Returns: table<properties: record<emailId: string, timeStamp: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: CertificateOrders_RetrieveCertificateEmailHistory
export def "certificate-orders-retrieve-certificate-email-history" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/retrieveEmailHistory"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Verify domain ownership for this certificate order
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/verifyDomainOwnership
# Returns: record
# operationId: CertificateOrders_VerifyDomainOwnership
export def "certificate-orders-verify-domain-ownership" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CertificateRegistration/certificateOrders/{name}/verifyDomainOwnership"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists domains under a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Domains_GetDomains
export def "domains-get-domains" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a domain
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# Returns: record
# operationId: Domains_DeleteDomain
export def "domains-delete-domain" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
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
  --force-hard-delete-domain: oneof<nothing, bool> # If true then the domain will be deleted immediately instead of after 24 hours
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: domainName, var: domain_name}]
    query: [{name: forceHardDeleteDomain, var: force_hard_delete_domain}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [204]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, domain_name: $domain_name, force_hard_delete_domain: $force_hard_delete_domain, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets details of a domain
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# Returns: record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Domains_GetDomain
export def "domains-get-domain" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: domainName, var: domain_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, domain_name: $domain_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a domain
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# Returns: record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Domains_UpdateDomain
export def "domains-update-domain" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: domainName, var: domain_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, domain_name: $domain_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a domain
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}
# Returns: record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Domains_CreateOrUpdateDomain
export def "domains-create-or-update-domain" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {autoRenew?: bool, consent?: record, contactAdmin?: record, contactBilling?: record, contactRegistrant?: record, contactTech?: record, createdTime?: string, domainNotRenewableReasons?: list<string>, expirationTime?: string, lastRenewedTime?: string, managedHostNames?: list, nameServers?: list<string>, privacy?: bool, provisioningState?: "Succeeded"|"Failed"|"Canceled"|"InProgress"|"Deleting", readyForDnsRecordManagement?: bool, ... (1 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --name: string # Resource Name
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: domainName, var: domain_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, domain_name: $domain_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, name: $name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves the latest status of a domain purchase operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}/operationresults/{operationId}
# Returns: record<properties: record<autoRenew: bool, consent: record<agreedAt: string, agreedBy: string, agreementKeys: list>, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdTime: string, domainNotRenewableReasons: list<string>, expirationTime: string, lastRenewedTime: string, managedHostNames: list<record>, nameServers: list<string>, privacy: bool, provisioningState: string, readyForDnsRecordManagement: bool, registrationStatus: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Domains_GetDomainOperation
export def "domains-get-domain-operation" [
  subscription_id: string
  resource_group_name: string
  domain_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DomainRegistration/domains/{domainName}/operationresults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: domainName, var: domain_name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, domain_name: $domain_name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns usage records for specified subscription and resource groups
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web.Admin/environments/{environmentName}/usage
# Returns: record
# operationId: Usage_GetUsage
export def "usage-get-usage" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --last-id: string # Last marker that was returned from the batch (required)
  --batch-size: int # size of the batch to be returned. (required, format: int32)
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web.Admin/environments/{environmentName}/usage"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: environmentName, var: environment_name}]
    query: [{name: lastId, var: last_id, required: true}, {name: batchSize, var: batch_size, required: true}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, environment_name: $environment_name, last_id: $last_id, batch_size: $batch_size, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get certificates for a subscription in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Certificates_GetCertificates
export def "certificates-get-certificates" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a certificate by name in a specified subscription and resourcegroup.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# Returns: record
# operationId: Certificates_DeleteCertificate
export def "certificates-delete-certificate" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a certificate by certificate name for a subscription in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# Returns: record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_GetCertificate
export def "certificates-get-certificate" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or modifies an existing certificate.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# Returns: record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_UpdateCertificate
export def "certificates-update-certificate" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or modifies an existing certificate.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}
# Returns: record<properties: record<cerBlob: string, expirationDate: string, friendlyName: string, hostNames: list<string>, hostingEnvironmentProfile: record<id: string, name: string, type: string>, issueDate: string, issuer: string, password: string, pfxBlob: string, publicKeyHash: string, selfLink: string, siteName: string, subjectName: string, thumbprint: string, valid: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_CreateOrUpdateCertificate
export def "certificates-create-or-update-certificate" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {cerBlob?: string, expirationDate?: string, friendlyName?: string, hostNames?: list<string>, hostingEnvironmentProfile?: record, issueDate?: string, issuer?: string, password?: string, pfxBlob?: string, publicKeyHash?: string, selfLink?: string, siteName?: string, subjectName?: string, thumbprint?: string, valid?: bool}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/certificates/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all mobile services in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ClassicMobileServices_GetClassicMobileServices
export def "classic-mobile-services-get-classic-mobile-services" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a mobile service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}
# Returns: record
# operationId: ClassicMobileServices_DeleteClassicMobileService
export def "classic-mobile-services-delete-classic-mobile-service" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a mobile service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}
# Returns: record<properties: record<name: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ClassicMobileServices_GetClassicMobileService
export def "classic-mobile-services-get-classic-mobile-service" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/classicMobileServices/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the certificate signing requests for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs
# Returns: table<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_GetCsrs
export def "certificates-get-csrs" [
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the certificate signing request.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# Returns: record
# operationId: Certificates_DeleteCsr
export def "certificates-delete-csr" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a certificate signing request by certificate name for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# Returns: record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_GetCsr
export def "certificates-get-csr" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or modifies an existing certificate signing request.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# Returns: record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_UpdateCsr
export def "certificates-update-csr" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or modifies an existing certificate signing request.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}
# Returns: record<properties: record<csrString: string, distinguishedName: string, hostingEnvironment: string, name: string, password: string, pfxBlob: string, publicKeyHash: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Certificates_CreateOrUpdateCsr
export def "certificates-create-or-update-csr" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {csrString?: string, distinguishedName?: string, hostingEnvironment?: string, name?: string, password?: string, pfxBlob?: string, publicKeyHash?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/csrs/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets deleted web apps in subscription
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/deletedSites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetDeletedSites
export def "sites-get-deleted-sites" [
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
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --include-site-types: string # Types of apps included in the response
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/deletedSites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: includeSiteTypes, var: include_site_types}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, properties_to_include: $properties_to_include, include_site_types: $include_site_types, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all hostingEnvironments (App Service Environments) in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironments
export def "hosting-environments-get-hosting-environments" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a hostingEnvironment (App Service Environment).
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# Returns: record
# operationId: HostingEnvironments_DeleteHostingEnvironment
export def "hosting-environments-delete-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --force-delete: oneof<nothing, bool> # Delete even if the hostingEnvironment (App Service Environment) contains resources
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: forceDelete, var: force_delete}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, force_delete: $force_delete, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get properties of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# Returns: record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_GetHostingEnvironment
export def "hosting-environments-get-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a hostingEnvironment (App Service Environment).
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}
# Returns: record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_CreateOrUpdateHostingEnvironment
export def "hosting-environments-create-or-update-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get used, available, and total worker capacity for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/compute
# Returns: record<nextLink: string, value: table<availableCapacity: int, computeMode: string, excludeFromCapacityAllocation: bool, isApplicableForAllComputeModes: bool, name: string, siteMode: string, totalCapacity: int, unit: string, workerSize: string, workerSizeId: int>>
# operationId: HostingEnvironments_GetHostingEnvironmentCapacities
export def "hosting-environments-get-hosting-environment-capacities" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/compute"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get IP addresses assigned to the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/virtualip
# Returns: record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentVips
export def "hosting-environments-get-hosting-environment-vips" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/capacities/virtualip"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get diagnostic information for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics
# Returns: table<diagnosicsOutput: string, name: string>
# operationId: HostingEnvironments_GetHostingEnvironmentDiagnostics
export def "hosting-environments-get-hosting-environment-diagnostics" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get diagnostic information for hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics/{diagnosticsName}
# Returns: record<diagnosicsOutput: string, name: string>
# operationId: HostingEnvironments_GetHostingEnvironmentDiagnosticsItem
export def "hosting-environments-get-hosting-environment-diagnostics-item" [
  subscription_id: string
  resource_group_name: string
  name: string
  diagnostics_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/diagnostics/{diagnosticsName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: diagnosticsName, var: diagnostics_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, diagnostics_name: $diagnostics_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get global metric definitions of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metricdefinitions
# Returns: record<properties: record<displayName: string, metricAvailabilities: list<record>, name: string, primaryAggregationType: string, unit: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_GetHostingEnvironmentMetricDefinitions
export def "hosting-environments-get-hosting-environment-metric-definitions" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get global metrics of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentMetrics
export def "hosting-environments-get-hosting-environment-metrics" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all multi role pools
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetMultiRolePools
export def "hosting-environments-get-multi-role-pools" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get properties of a multiRole pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default
# Returns: record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_GetMultiRolePool
export def "hosting-environments-get-multi-role-pool" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a multiRole pool.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default
# Returns: record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_CreateOrUpdateMultiRolePool
export def "hosting-environments-create-or-update-multi-role-pool" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, sku: $sku, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metric definitions for a specific instance of a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metricdefinitions
# Returns: record
# operationId: HostingEnvironments_GetMultiRolePoolInstanceMetricDefinitions
export def "hosting-environments-get-multi-role-pool-instance-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instance, var: instance}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance: $instance, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for a specific instance of a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metrics
# Returns: record
# operationId: HostingEnvironments_GetMultiRolePoolInstanceMetrics
export def "hosting-environments-get-multi-role-pool-instance-metrics" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance: string
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
  --details: oneof<nothing, bool> # Include instance details
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/instances/{instance}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instance, var: instance}]
    query: [{name: details, var: details}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance: $instance, details: $details, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metric definitions for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metricdefinitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleMetricDefinitions
export def "hosting-environments-get-hosting-environment-multi-role-metric-definitions" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleMetrics
export def "hosting-environments-get-hosting-environment-multi-role-metrics" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --start-time: string # Beginning time of metrics query
  --end-time: string # End time of metrics query
  --time-grain: string # Time granularity of metrics query
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: timeGrain, var: time_grain}, {name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, start_time: $start_time, end_time: $end_time, time_grain: $time_grain, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get available skus for scaling a multiRole pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/skus
# Returns: record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>
# operationId: HostingEnvironments_GetMultiRolePoolSkus
export def "hosting-environments-get-multi-role-pool-skus" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get usages for a multiRole pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/usages
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentMultiRoleUsages
export def "hosting-environments-get-hosting-environment-multi-role-usages" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/multiRolePools/default/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List all currently running operations on the hostingEnvironment (App Service Environment)
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations
# Returns: record
# operationId: HostingEnvironments_GetHostingEnvironmentOperations
export def "hosting-environments-get-hosting-environment-operations" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get status of an operation on a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations/{operationId}
# Returns: record
# operationId: HostingEnvironments_GetHostingEnvironmentOperation
export def "hosting-environments-get-hosting-environment-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Reboots all machines in a hostingEnvironment (App Service Environment).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/reboot
# Returns: record
# operationId: HostingEnvironments_RebootHostingEnvironment
export def "hosting-environments-reboot-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/reboot"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resumes the hostingEnvironment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/resume
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_ResumeHostingEnvironment
export def "hosting-environments-resume-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/resume"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all serverfarms (App Service Plans) on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/serverfarms
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentServerFarms
export def "hosting-environments-get-hosting-environment-server-farms" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/serverfarms"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all sites on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/sites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentSites
export def "hosting-environments-get-hosting-environment-sites" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Comma separated list of site properties to include
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/sites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, properties_to_include: $properties_to_include, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Suspends the hostingEnvironment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/suspend
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_SuspendHostingEnvironment
export def "hosting-environments-suspend-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/suspend"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get global usages of hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/usages
# Returns: record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentUsages
export def "hosting-environments-get-hosting-environment-usages" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all serverfarms (App Service Plans) on the hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/webhostingplans
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentWebHostingPlans
export def "hosting-environments-get-hosting-environment-web-hosting-plans" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/webhostingplans"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all worker pools
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetWorkerPools
export def "hosting-environments-get-worker-pools" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get properties of a worker pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}
# Returns: record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_GetWorkerPool
export def "hosting-environments-get-worker-pool" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a worker pool.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}
# Returns: record<properties: record<computeMode: string, instanceNames: list<string>, workerCount: int, workerSize: string, workerSizeId: int>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: HostingEnvironments_CreateOrUpdateWorkerPool
export def "hosting-environments-create-or-update-worker-pool" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {computeMode?: "Shared"|"Dedicated"|"Dynamic", instanceNames?: list<string>, workerCount?: int, workerSize?: string, workerSizeId?: int}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, api_version: $api_version, properties: $properties, sku: $sku, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metric definitions for a specific instance of a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metricdefinitions
# Returns: record
# operationId: HostingEnvironments_GetWorkerPoolInstanceMetricDefinitions
export def "hosting-environments-get-worker-pool-instance-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  instance: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}, {name: instance, var: instance}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, instance: $instance, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for a specific instance of a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metrics
# Returns: record
# operationId: HostingEnvironments_GetWorkerPoolInstanceMetrics
export def "hosting-environments-get-worker-pool-instance-metrics" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
  instance: string
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
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/instances/{instance}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}, {name: instance, var: instance}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, instance: $instance, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metric definitions for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metricdefinitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerMetricDefinitions
export def "hosting-environments-get-hosting-environment-web-worker-metric-definitions" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get metrics for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerMetrics
export def "hosting-environments-get-hosting-environment-web-worker-metrics" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --details: oneof<nothing, bool> # Include instance details
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get available skus for scaling a worker pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/skus
# Returns: record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>>
# operationId: HostingEnvironments_GetWorkerPoolSkus
export def "hosting-environments-get-worker-pool-skus" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/skus"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get usages for a worker pool of a hostingEnvironment (App Service Environment).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/usages
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: HostingEnvironments_GetHostingEnvironmentWebWorkerUsages
export def "hosting-environments-get-hosting-environment-web-worker-usages" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_pool_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/hostingEnvironments/{name}/workerPools/{workerPoolName}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerPoolName, var: worker_pool_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_pool_name: $worker_pool_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all managed hosting environments in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironments
export def "managed-hosting-environments-get-managed-hosting-environments" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete a managed hosting environment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# Returns: record
# operationId: ManagedHostingEnvironments_DeleteManagedHostingEnvironment
export def "managed-hosting-environments-delete-managed-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --force-delete: oneof<nothing, bool> # Delete even if the managed hosting environment contains resources
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: forceDelete, var: force_delete}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, force_delete: $force_delete, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get properties of a managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# Returns: record<properties: record<apiManagementAccount: string, dnsSuffix: string, environmentIsHealthy: bool, environmentStatus: string, ipsslAddressCount: int, location: string, name: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, virtualNetwork: record<id: string, name: string, subnet: string, type: string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironment
export def "managed-hosting-environments-get-managed-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create or update a managed hosting environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}
# Returns: record<properties: record<allowedMultiSizes: string, allowedWorkerSizes: string, apiManagementAccountId: string, clusterSettings: list<record>, databaseEdition: string, databaseServiceObjective: string, dnsSuffix: string, environmentCapacities: list<record>, environmentIsHealthy: bool, environmentStatus: string, internalLoadBalancingMode: string, ipsslAddressCount: int, lastAction: string, lastActionResult: string, location: string, maximumNumberOfMachines: int, multiRoleCount: int, multiSize: string, name: string, networkAccessControlList: list<record>, provisioningState: string, resourceGroup: string, status: string, subscriptionId: string, suspended: bool, upgradeDomains: int, vipMappings: list<record>, virtualNetwork: record<id: string, name: string, subnet: string, type: string>, vnetName: string, vnetResourceGroupName: string, vnetSubnetName: string, workerPools: list<record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ManagedHostingEnvironments_CreateOrUpdateManagedHostingEnvironment
export def "managed-hosting-environments-create-or-update-managed-hosting-environment" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {allowedMultiSizes?: string, allowedWorkerSizes?: string, apiManagementAccountId?: string, clusterSettings?: list, databaseEdition?: string, databaseServiceObjective?: string, dnsSuffix?: string, environmentCapacities?: list, environmentIsHealthy?: bool, environmentStatus?: string, internalLoadBalancingMode?: "None"|"Web"|"Publishing", ipsslAddressCount?: int, lastAction?: string, lastActionResult?: string, location?: string, maximumNumberOfMachines?: int, multiRoleCount?: int, multiSize?: string, ... (14 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get list of ip addresses assigned to a managed hosting environment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/capacities/virtualip
# Returns: record<internalIpAddress: string, outboundIpAddresses: list<string>, serviceIpAddress: string, vipMappings: table<inUse: bool, internalHttpPort: int, internalHttpsPort: int, virtualIP: string>>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentVips
export def "managed-hosting-environments-get-managed-hosting-environment-vips" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/capacities/virtualip"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get status of an operation on a managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/operations/{operationId}
# Returns: record
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentOperation
export def "managed-hosting-environments-get-managed-hosting-environment-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/operations/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all serverfarms (App Service Plans) on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/serverfarms
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentServerFarms
export def "managed-hosting-environments-get-managed-hosting-environment-server-farms" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/serverfarms"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all sites on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/sites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentSites
export def "managed-hosting-environments-get-managed-hosting-environment-sites" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Comma separated list of site properties to include
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/sites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, properties_to_include: $properties_to_include, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all serverfarms (App Service Plans) on the managed hosting environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/webhostingplans
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ManagedHostingEnvironments_GetManagedHostingEnvironmentWebHostingPlans
export def "managed-hosting-environments-get-managed-hosting-environment-web-hosting-plans" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/managedHostingEnvironments/{name}/webhostingplans"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets collection of App Service Plans in a resource group for a given subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms
# Returns: record<nextLink: string, value: table<properties: record, sku: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ServerFarms_GetServerFarms
export def "server-farms-get-server-farms" [
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a App Service Plan
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# Returns: record
# operationId: ServerFarms_DeleteServerFarm
export def "server-farms-delete-server-farm" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets specified App Service Plan in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# Returns: record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetServerFarm
export def "server-farms-get-server-farm" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or updates an App Service Plan
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}
# Returns: record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_CreateOrUpdateServerFarm
export def "server-farms-create-or-update-server-farm" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --allow-pending-state: oneof<nothing, bool> # OBSOLETE: If true, allow pending state for App Service Plan
  --api-version: string # API Version (required)
  --properties: any # shape: {adminSiteName?: string, hostingEnvironmentProfile?: record, maximumNumberOfWorkers?: int, name?: string, perSiteScaling?: bool, reserved?: bool, workerTierName?: string}
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: allowPendingState, var: allow_pending_state}, {name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: sku, var: sku}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, allow_pending_state: $allow_pending_state, api_version: $api_version, properties: $properties, sku: $sku, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List of metrics that can be queried for an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metricdefinitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ServerFarms_GetServerFarmMetricDefintions
export def "server-farms-get-server-farm-metric-defintions" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Queries for App Service Plan metrics
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: ServerFarms_GetServerFarmMetrics
export def "server-farms-get-server-farm-metrics" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # If true, metrics are broken down per App Service Plan instance
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a server farm operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/operationresults/{operationId}
# Returns: record<properties: record<adminSiteName: string, geoRegion: string, hostingEnvironmentProfile: record<id: string, name: string, type: string>, maximumNumberOfWorkers: int, name: string, numberOfSites: int, perSiteScaling: bool, reserved: bool, resourceGroup: string, status: string, subscription: string, workerTierName: string>, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetServerFarmOperation
export def "server-farms-get-server-farm-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/operationresults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restarts web apps in a specified App Service Plan
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/restartSites
# Returns: record
# operationId: ServerFarms_RestartSitesForServerFarm
export def "server-farms-restart-sites-for-server-farm" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the apps if necessary. Hard restart always restarts and reprovisions the apps
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/restartSites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: softRestart, var: soft_restart}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, soft_restart: $soft_restart, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of Apps associated with an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/sites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: ServerFarms_GetServerFarmSites
export def "server-farms-get-server-farm-sites" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --skip-token: string # Skip to of web apps in a list. If specified, the resulting list will contain web apps starting from (including) the skipToken. Else, the resulting list contains web apps from the start of the list
  --filter: string # Supported filter: $filter=state eq running. Returns only web apps that are currently running
  --top: string # List page size. If specified, results are paged.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/sites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: "$skipToken", var: skip_token}, {name: "$filter", var: filter}, {name: "$top", var: top}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, skip_token: $skip_token, filter: $filter, top: $top, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of VNets associated with App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections
# Returns: table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetVnetsForServerFarm
export def "server-farms-get-vnets-for-server-farm" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a vnet associated with an App Service Plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetVnetFromServerFarm
export def "server-farms-get-vnet-from-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the vnet gateway.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetServerFarmVnetGateway
export def "server-farms-get-server-farm-vnet-gateway" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the vnet gateway
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_UpdateServerFarmVnetGateway
export def "server-farms-update-server-farm-vnet-gateway" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of all routes associated with a vnet, in an app service plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes
# Returns: table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetRoutesForVnet
export def "server-farms-get-routes-for-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes an existing route for a vnet in an app service plan.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# Returns: record
# operationId: ServerFarms_DeleteVnetRoute
export def "server-farms-delete-vnet-route" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, route_name: $route_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a specific route associated with a vnet, in an app service plan
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# Returns: table<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_GetRouteForVnet
export def "server-farms-get-route-for-vnet" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, route_name: $route_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new route or updates an existing route for a vnet in an app service plan.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# Returns: record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_UpdateVnetRoute
export def "server-farms-update-vnet-route" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, route_name: $route_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new route or updates an existing route for a vnet in an app service plan.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}
# Returns: record<properties: record<endAddress: string, name: string, routeType: string, startAddress: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: ServerFarms_CreateOrUpdateVnetRoute
export def "server-farms-create-or-update-vnet-route" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  route_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {endAddress?: string, name?: string, routeType?: string, startAddress?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/virtualNetworkConnections/{vnetName}/routes/{routeName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: routeName, var: route_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, route_name: $route_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Submit a reboot request for a worker machine in the specified server farm
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/workers/{workerName}/reboot
# Returns: record
# operationId: ServerFarms_RebootWorkerForServerFarm
export def "server-farms-reboot-worker-for-server-farm" [
  subscription_id: string
  resource_group_name: string
  name: string
  worker_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/serverfarms/{name}/workers/{workerName}/reboot"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: workerName, var: worker_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, worker_name: $worker_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web apps for a subscription in the specified resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSites
export def "sites-get-sites" [
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
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --include-site-types: string # Types of apps included in the response
  --include-slots: oneof<nothing, bool> # Whether or not to include deployments slots in results
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: includeSiteTypes, var: include_site_types}, {name: includeSlots, var: include_slots}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, properties_to_include: $properties_to_include, include_site_types: $include_site_types, include_slots: $include_slots, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# Returns: record
# operationId: Sites_DeleteSite
export def "sites-delete-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --delete-metrics: string # If true, web app metrics are also deleted
  --delete-empty-server-farm: string # If true and App Service Plan is empty after web app deletion, App Service Plan is also deleted
  --skip-dns-registration: string # If true, DNS registration is skipped
  --delete-all-slots: string # If true, all slots associated with web app are also deleted
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: deleteMetrics, var: delete_metrics}, {name: deleteEmptyServerFarm, var: delete_empty_server_farm}, {name: skipDnsRegistration, var: skip_dns_registration}, {name: deleteAllSlots, var: delete_all_slots}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, delete_metrics: $delete_metrics, delete_empty_server_farm: $delete_empty_server_farm, skip_dns_registration: $skip_dns_registration, delete_all_slots: $delete_all_slots, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get details of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSite
export def "sites-get-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --properties-to-include: string # Additional web app properties included in the response
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, properties_to_include: $properties_to_include, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new web app or modifies an existing web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSite
export def "sites-create-or-update-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --skip-dns-registration: string # If true web app hostname is not registered with DNS on creation. This parameter is only used for app creation
  --skip-custom-domain-verification: string # If true, custom (non *.azurewebsites.net) domains associated with web app are not verified.
  --force-dns-registration: string # If true, web app hostname is force registered with DNS
  --ttl-in-seconds: string # Time to live in seconds for web app's default domain name
  --api-version: string # API Version (required)
  --properties: any # shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: skipDnsRegistration, var: skip_dns_registration}, {name: skipCustomDomainVerification, var: skip_custom_domain_verification}, {name: forceDnsRegistration, var: force_dns_registration}, {name: ttlInSeconds, var: ttl_in_seconds}, {name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, skip_dns_registration: $skip_dns_registration, skip_custom_domain_verification: $skip_custom_domain_verification, force_dns_registration: $force_dns_registration, ttl_in_seconds: $ttl_in_seconds, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Applies the configuration settings from the target slot onto the current slot
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/applySlotConfig
# Returns: record
# operationId: Sites_ApplySlotConfigToProduction
export def "sites-apply-slot-config-to-production" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/applySlotConfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates web app backup
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backup
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_BackupSite
export def "sites-backup-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all available backups for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_ListSiteBackups
export def "sites-list-site-backups" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Discovers existing web app backups that can be restored
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/discover
# Returns: record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_DiscoverSiteRestore
export def "sites-discover-site-restore" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/discover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a backup from Azure Storage
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_DeleteBackup
export def "sites-delete-backup" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, backup_id: $backup_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets status of a web app backup that may be in progress.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupStatus
export def "sites-get-site-backup-status" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, backup_id: $backup_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/list
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupStatusSecrets
export def "sites-get-site-backup-status-secrets" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, backup_id: $backup_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restores a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/restore
# Returns: record<properties: record<operationId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_RestoreSite
export def "sites-restore-site" [
  subscription_id: string
  resource_group_name: string
  name: string
  backup_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/backups/{backupId}/restore"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, backup_id: $backup_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the application settings of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteAppSettings
export def "sites-update-site-app-settings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the application settings of web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteAppSettings
export def "sites-list-site-app-settings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/appsettings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Authentication / Authorization settings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings
# Returns: record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>
# operationId: Sites_UpdateSiteAuthSettings
export def "sites-update-site-auth-settings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --aad-client-id: string
  --additional-login-params: list<string> # Gets or sets a list of login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
  --allowed-audiences: list<string> # Gets or sets a list of allowed audience values to consider when validating JWTs issued by Azure Active Directory. Note that the {Microsoft.Web.Hosting.Administration.SiteAuthSettings.ClientId} value is always considered an allowed audience, regardless of this setting.
  --allowed-external-redirect-urls: list<string> # Gets or sets a collection of external URLs that can be redirected to as part of logging in or logging out of the web app. Note that the query string part of the URL is ignored. This is an advanced setting typically only needed by Windows Store application backends. Note that URLs within the current domain are always implicitly allowed.
  --client-id: string # Gets or sets the Client ID of this relying party application, known as the client_id. This setting is required for enabling OpenID Connection authentication with Azure Active Directory or other 3rd party OpenID Connect providers. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --client-secret: string # Gets or sets the Client Secret of this relying party application (in Azure Active Directory, this is also referred to as the Key). This setting is optional. If no client secret is configured, the OpenID Connect implicit auth flow is used to authenticate end users. Otherwise, the OpenID Connect Authorization Code Flow is used to authenticate end users. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --default-provider: string@default-provider-completer # Gets or sets the default authentication provider to use when multiple providers are configured. This setting is only needed if multiple providers are configured and the unauthenticated client action is set to "RedirectToLoginPage".
  --enabled: oneof<nothing, bool> # Gets or sets a value indicating whether the Authentication / Authorization feature is enabled for the current app.
  --facebook-app-id: string # Gets or sets the App ID of the Facebook app used for login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-app-secret: string # Gets or sets the App Secret of the Facebook app used for Facebook Login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Facebook Login authentication. This setting is optional. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --google-client-id: string # Gets or sets the OpenID Connect Client ID for the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-client-secret: string # Gets or sets the client secret associated with the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Google Sign-In authentication. This setting is optional. If not specified, "openid", "profile", and "email" are used as default scopes. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --http-api-prefix-path: string # Gets or sets the relative path prefix used by platform HTTP APIs. Changing this value is not recommended except for compatibility reasons.
  --issuer: string # Gets or sets the OpenID Connect Issuer URI that represents the entity which issues access tokens for this application. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/. This URI is a case-sensitive identifier for the token issuer. More information on OpenID Connect Discovery: http://openid.net/specs/openid-connect-discovery-1_0.html
  --microsoft-account-client-id: string # Gets or sets the OAuth 2.0 client ID that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-client-secret: string # Gets or sets the OAuth 2.0 client secret that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Microsoft Account authentication. This setting is optional. If not specified, "wl.basic" is used as the default scope. Microsoft Account Scopes and permissions documentation: https://msdn.microsoft.com/en-us/library/dn631845.aspx
  --open-id-issuer: string
  --token-refresh-extension-hours: float # Gets or sets the number of hours after session token expiration that a session token can be used to call the token refresh API. The default is 72 hours. (format: double)
  --token-store-enabled: oneof<nothing, bool> # Gets or sets a value indicating whether to durably store platform-specific security tokens obtained during login flows. This capability is disabled by default.
  --twitter-consumer-key: string # Gets or sets the OAuth 1.0a consumer key of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --twitter-consumer-secret: string # Gets or sets the OAuth 1.0a consumer secret of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --unauthenticated-client-action: string@unauthenticated-client-action-completer # Gets or sets the action to take when an unauthenticated client attempts to access the app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadClientId, var: aad_client_id}, {name: additionalLoginParams, var: additional_login_params}, {name: allowedAudiences, var: allowed_audiences}, {name: allowedExternalRedirectUrls, var: allowed_external_redirect_urls}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: defaultProvider, var: default_provider}, {name: enabled, var: enabled}, {name: facebookAppId, var: facebook_app_id}, {name: facebookAppSecret, var: facebook_app_secret}, {name: facebookOAuthScopes, var: facebook_o_auth_scopes}, {name: googleClientId, var: google_client_id}, {name: googleClientSecret, var: google_client_secret}, {name: googleOAuthScopes, var: google_o_auth_scopes}, {name: httpApiPrefixPath, var: http_api_prefix_path}, {name: issuer, var: issuer}, {name: microsoftAccountClientId, var: microsoft_account_client_id}, {name: microsoftAccountClientSecret, var: microsoft_account_client_secret}, {name: microsoftAccountOAuthScopes, var: microsoft_account_o_auth_scopes}, {name: openIdIssuer, var: open_id_issuer}, {name: tokenRefreshExtensionHours, var: token_refresh_extension_hours}, {name: tokenStoreEnabled, var: token_store_enabled}, {name: twitterConsumerKey, var: twitter_consumer_key}, {name: twitterConsumerSecret, var: twitter_consumer_secret}, {name: unauthenticatedClientAction, var: unauthenticated_client_action}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, aad_client_id: $aad_client_id, additional_login_params: $additional_login_params, allowed_audiences: $allowed_audiences, allowed_external_redirect_urls: $allowed_external_redirect_urls, client_id: $client_id, client_secret: $client_secret, default_provider: $default_provider, enabled: $enabled, facebook_app_id: $facebook_app_id, facebook_app_secret: $facebook_app_secret, facebook_o_auth_scopes: $facebook_o_auth_scopes, google_client_id: $google_client_id, google_client_secret: $google_client_secret, google_o_auth_scopes: $google_o_auth_scopes, http_api_prefix_path: $http_api_prefix_path, issuer: $issuer, microsoft_account_client_id: $microsoft_account_client_id, microsoft_account_client_secret: $microsoft_account_client_secret, microsoft_account_o_auth_scopes: $microsoft_account_o_auth_scopes, open_id_issuer: $open_id_issuer, token_refresh_extension_hours: $token_refresh_extension_hours, token_store_enabled: $token_store_enabled, twitter_consumer_key: $twitter_consumer_key, twitter_consumer_secret: $twitter_consumer_secret, unauthenticated_client_action: $unauthenticated_client_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the Authentication / Authorization settings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings/list
# Returns: record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>
# operationId: Sites_ListSiteAuthSettings
export def "sites-list-site-auth-settings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/authsettings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates backup configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup
# Returns: record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteBackupConfiguration
export def "sites-update-site-backup-configuration" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the backup configuration for a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup/list
# Returns: record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupConfiguration
export def "sites-get-site-backup-configuration" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/backup/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the connection strings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteConnectionStrings
export def "sites-update-site-connection-strings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: record # Connection strings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the connection strings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteConnectionStrings
export def "sites-list-site-connection-strings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/connectionstrings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app logs configuration
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# Returns: record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteLogsConfig
export def "sites-get-site-logs-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs
# Returns: record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteLogsConfig
export def "sites-update-site-logs-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/logs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteMetadata
export def "sites-update-site-metadata" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app meta data.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteMetadata
export def "sites-list-site-metadata" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/metadata/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app publishing credentials
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/publishingcredentials/list
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSitePublishingCredentials
export def "sites-list-site-publishing-credentials" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/publishingcredentials/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the names of application settings and connection string that remain with the slot during swap operation
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# Returns: record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSlotConfigNames
export def "sites-get-slot-config-names" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the names of application settings and connection string that remain with the slot during swap operation
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames
# Returns: record<properties: record<appSettingNames: list<string>, connectionStringNames: list<string>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSlotConfigNames
export def "sites-update-slot-config-names" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {appSettingNames?: list<string>, connectionStringNames?: list<string>}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/slotConfigNames"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the configuration of the web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteConfig
export def "sites-get-site-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteConfig
export def "sites-update-site-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteConfig
export def "sites-create-or-update-site-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetDeployments
export def "sites-get-deployments" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# Returns: record
# operationId: Sites_DeleteDeployment
export def "sites-delete-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetDeployment
export def "sites-get-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateDeployment
export def "sites-create-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id (spec name: id)
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: body_id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, id: $id, api_version: $api_version, properties: $properties, body_id: $body_id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get web app hostname bindings
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteHostNameBindings
export def "sites-get-site-host-name-bindings" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a host name binding
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# Returns: record
# operationId: Sites_DeleteSiteHostNameBinding
export def "sites-delete-site-host-name-binding" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, host_name: $host_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get web app binding for a hostname
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# Returns: record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteHostNameBinding
export def "sites-get-site-host-name-binding" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, host_name: $host_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a web app hostname binding
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}
# Returns: record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteHostNameBinding
export def "sites-create-or-update-site-host-name-binding" [
  subscription_id: string
  resource_group_name: string
  name: string
  host_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, host_name: $host_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves all BizTalk Hybrid Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteRelayServiceConnections
export def "sites-list-site-relay-service-connections" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the association to a BizTalk Hybrid Connection, identified by its entity name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# Returns: record
# operationId: Sites_DeleteSiteRelayServiceConnection
export def "sites-delete-site-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, entity_name: $entity_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a BizTalk Hybrid Connection identified by its entity name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteRelayServiceConnection
export def "sites-get-site-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, entity_name: $entity_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteRelayServiceConnection
export def "sites-update-site-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, entity_name: $entity_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteRelayServiceConnection
export def "sites-create-or-update-site-relay-service-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  entity_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, entity_name: $entity_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all instance of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteInstanceIdentifiers
export def "sites-get-site-instance-identifiers" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetInstanceDeployments
export def "sites-get-instance-deployments" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# Returns: record
# operationId: Sites_DeleteInstanceDeployment
export def "sites-delete-instance-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance_id: $instance_id, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetInstanceDeployment
export def "sites-get-instance-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance_id: $instance_id, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateInstanceDeployment
export def "sites-create-instance-deployment" [
  subscription_id: string
  resource_group_name: string
  name: string
  instance_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id (spec name: id)
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: body_id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, instance_id: $instance_id, id: $id, api_version: $api_version, properties: $properties, body_id: $body_id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new web app or modifies an existing web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/iscloneable
# Returns: record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>>
# operationId: Sites_IsSiteCloneable
export def "sites-is-site-cloneable" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/iscloneable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets metric definitions for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metricdefinitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteMetricDefinitions
export def "sites-get-site-metric-definitions" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets metrics for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: Sites_GetSiteMetrics
export def "sites-get-site-metrics" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # If true, metric details are included in response
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a view of all network features in use on this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkFeatures/{view}
# Returns: record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, virtualNetworkName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteNetworkFeatures
export def "sites-get-site-network-features" [
  subscription_id: string
  resource_group_name: string
  name: string
  view: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/networkFeatures/{view}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: view, var: view}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, view: $view, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generates new random app publishing password
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/newpassword
# Returns: record
# operationId: Sites_GenerateNewSitePublishingPassword
export def "sites-generate-new-site-publishing-password" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/newpassword"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the operation for a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/operationresults/{operationId}
# Returns: record
# operationId: Sites_GetSiteOperation
export def "sites-get-site-operation" [
  subscription_id: string
  resource_group_name: string
  name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/operationresults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons
#
# Returns: record
# operationId: Sites_ListSitePremierAddOns
export def "sites-list-site-premier-add-ons" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_DeleteSitePremierAddOn
export def "sites-delete-site-premier-add-on" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, premier_add_on_name: $premier_add_on_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_GetSitePremierAddOn
export def "sites-get-site-premier-add-on" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, premier_add_on_name: $premier_add_on_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_AddSitePremierAddOn
export def "sites-add-site-premier-add-on" [
  subscription_id: string
  resource_group_name: string
  name: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
  --location: string # Geo region resource belongs to e.g. SouthCentralUS, SouthEastAsia
  --plan: record # The plan object in an ARM, represents a marketplace plan — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --tags: record # Tags associated with resource
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, premier_add_on_name: $premier_add_on_name, api_version: $api_version, location: $location, plan: $plan, properties: $properties, sku: $sku, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the publishing profile for web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publishxml
# Returns: binary
# operationId: Sites_ListSitePublishingProfileXml
export def "sites-list-site-publishing-profile-xml" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --format: string # Name of the format. Valid values are: FileZilla3 WebDeploy -- default Ftp
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/publishxml"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Recovers a deleted web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/recover
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_RecoverSite
export def "sites-recover-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --recover-config: oneof<nothing, bool> # If true, then the website's configuration will be reverted to its state at SnapshotTime
  --site-name: string # [Optional] Destination web app name into which web app should be recovered. This is case when new web app should be created instead.
  --slot-name: string # [Optional] Destination web app slot name into which web app should be recovered
  --snapshot-time: string # Point in time in which the site recover should be attempted. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/recover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: recoverConfig, var: recover_config}, {name: siteName, var: site_name}, {name: slotName, var: slot_name}, {name: snapshotTime, var: snapshot_time}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, recover_config: $recover_config, site_name: $site_name, slot_name: $slot_name, snapshot_time: $snapshot_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resets the configuration settings of the current slot if they were previously modified by calling ApplySlotConfig API
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/resetSlotConfig
# Returns: record
# operationId: Sites_ResetProductionSlotConfig
export def "sites-reset-production-slot-config" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/resetSlotConfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restarts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restart
# Returns: record
# operationId: Sites_RestartSite
export def "sites-restart-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the app if necessary. Hard restart always restarts and reprovisions the app
  --synchronous: oneof<nothing, bool> # If true then the API will block until the app has been restarted
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: softRestart, var: soft_restart}, {name: synchronous, var: synchronous}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, soft_restart: $soft_restart, synchronous: $synchronous, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all the slots for a web apps
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteSlots
export def "sites-get-site-slots" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --properties-to-include: string # List of app properties to include in the response
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, properties_to_include: $properties_to_include, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# Returns: record
# operationId: Sites_DeleteSiteSlot
export def "sites-delete-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --delete-metrics: string # If true, web app metrics are also deleted
  --delete-empty-server-farm: string # If true and App Service Plan is empty after web app deletion, App Service Plan is also deleted
  --skip-dns-registration: string # If true, DNS registration is skipped
  --delete-all-slots: string # If true, all slots associated with web app are also deleted
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: deleteMetrics, var: delete_metrics}, {name: deleteEmptyServerFarm, var: delete_empty_server_farm}, {name: skipDnsRegistration, var: skip_dns_registration}, {name: deleteAllSlots, var: delete_all_slots}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, delete_metrics: $delete_metrics, delete_empty_server_farm: $delete_empty_server_farm, skip_dns_registration: $skip_dns_registration, delete_all_slots: $delete_all_slots, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get details of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteSlot
export def "sites-get-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --properties-to-include: string # Additional web app properties included in the response
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: propertiesToInclude, var: properties_to_include}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, properties_to_include: $properties_to_include, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new web app or modifies an existing web app.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteSlot
export def "sites-create-or-update-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --skip-dns-registration: string # If true web app hostname is not registered with DNS on creation. This parameter is only used for app creation
  --skip-custom-domain-verification: string # If true, custom (non *.azurewebsites.net) domains associated with web app are not verified.
  --force-dns-registration: string # If true, web app hostname is force registered with DNS
  --ttl-in-seconds: string # Time to live in seconds for web app's default domain name
  --api-version: string # API Version (required)
  --properties: any # shape: {clientAffinityEnabled?: bool, clientCertEnabled?: bool, cloningInfo?: record, containerSize?: int, enabled?: bool, gatewaySiteName?: string, hostNameSslStates?: list, hostNamesDisabled?: bool, hostingEnvironmentProfile?: record, maxNumberOfWorkers?: int, microService?: string, name?: string, scmSiteAlsoStopped?: bool, serverFarmId?: string, siteConfig?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: skipDnsRegistration, var: skip_dns_registration}, {name: skipCustomDomainVerification, var: skip_custom_domain_verification}, {name: forceDnsRegistration, var: force_dns_registration}, {name: ttlInSeconds, var: ttl_in_seconds}, {name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, skip_dns_registration: $skip_dns_registration, skip_custom_domain_verification: $skip_custom_domain_verification, force_dns_registration: $force_dns_registration, ttl_in_seconds: $ttl_in_seconds, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Applies the configuration settings from the target slot onto the current slot
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/applySlotConfig
# Returns: record
# operationId: Sites_ApplySlotConfigSlot
export def "sites-apply-slot-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/applySlotConfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates web app backup
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backup
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_BackupSiteSlot
export def "sites-backup-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all available backups for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_ListSiteBackupsSlot
export def "sites-list-site-backups-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Discovers existing web app backups that can be restored
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/discover
# Returns: record<properties: record<adjustConnectionStrings: bool, blobName: string, databases: list<record>, hostingEnvironment: string, ignoreConflictingHostNames: bool, operationType: string, overwrite: bool, siteName: string, storageAccountUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_DiscoverSiteRestoreSlot
export def "sites-discover-site-restore-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/discover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a backup from Azure Storage
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_DeleteBackupSlot
export def "sites-delete-backup-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, backup_id: $backup_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets status of a web app backup that may be in progress.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupStatusSlot
export def "sites-get-site-backup-status-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, backup_id: $backup_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets status of a web app backup that may be in progress, including secrets associated with the backup, such as the Azure Storage SAS URL. Also can be used to update the SAS URL for the backup if a new URL is passed in the request body.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/list
# Returns: record<properties: record<blobName: string, correlationId: string, created: string, databases: list<record>, finishedTimeStamp: string, id: int, lastRestoreTimeStamp: string, log: string, name: string, scheduled: bool, sizeInBytes: int, status: string, storageAccountUrl: string, websiteSizeInBytes: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupStatusSecretsSlot
export def "sites-get-site-backup-status-secrets-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, backup_id: $backup_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restores a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/restore
# Returns: record<properties: record<operationId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_RestoreSiteSlot
export def "sites-restore-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  backup_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {adjustConnectionStrings?: bool, blobName?: string, databases?: list, hostingEnvironment?: string, ignoreConflictingHostNames?: bool, operationType: "Default"|"Clone"|"Relocation", overwrite?: bool, siteName?: string, storageAccountUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/backups/{backupId}/restore"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: backupId, var: backup_id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, backup_id: $backup_id, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the application settings of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteAppSettingsSlot
export def "sites-update-site-app-settings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the application settings of web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteAppSettingsSlot
export def "sites-list-site-app-settings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/appsettings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Authentication / Authorization settings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings
# Returns: record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>
# operationId: Sites_UpdateSiteAuthSettingsSlot
export def "sites-update-site-auth-settings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --aad-client-id: string
  --additional-login-params: list<string> # Gets or sets a list of login parameters to send to the OpenID Connect authorization endpoint when a user logs in. Each parameter must be in the form "key=value".
  --allowed-audiences: list<string> # Gets or sets a list of allowed audience values to consider when validating JWTs issued by Azure Active Directory. Note that the {Microsoft.Web.Hosting.Administration.SiteAuthSettings.ClientId} value is always considered an allowed audience, regardless of this setting.
  --allowed-external-redirect-urls: list<string> # Gets or sets a collection of external URLs that can be redirected to as part of logging in or logging out of the web app. Note that the query string part of the URL is ignored. This is an advanced setting typically only needed by Windows Store application backends. Note that URLs within the current domain are always implicitly allowed.
  --client-id: string # Gets or sets the Client ID of this relying party application, known as the client_id. This setting is required for enabling OpenID Connection authentication with Azure Active Directory or other 3rd party OpenID Connect providers. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --client-secret: string # Gets or sets the Client Secret of this relying party application (in Azure Active Directory, this is also referred to as the Key). This setting is optional. If no client secret is configured, the OpenID Connect implicit auth flow is used to authenticate end users. Otherwise, the OpenID Connect Authorization Code Flow is used to authenticate end users. More information on OpenID Connect: http://openid.net/specs/openid-connect-core-1_0.html
  --default-provider: string@default-provider-completer # Gets or sets the default authentication provider to use when multiple providers are configured. This setting is only needed if multiple providers are configured and the unauthenticated client action is set to "RedirectToLoginPage".
  --enabled: oneof<nothing, bool> # Gets or sets a value indicating whether the Authentication / Authorization feature is enabled for the current app.
  --facebook-app-id: string # Gets or sets the App ID of the Facebook app used for login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-app-secret: string # Gets or sets the App Secret of the Facebook app used for Facebook Login. This setting is required for enabling Facebook Login. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --facebook-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Facebook Login authentication. This setting is optional. Facebook Login documentation: https://developers.facebook.com/docs/facebook-login
  --google-client-id: string # Gets or sets the OpenID Connect Client ID for the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-client-secret: string # Gets or sets the client secret associated with the Google web application. This setting is required for enabling Google Sign-In. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --google-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Google Sign-In authentication. This setting is optional. If not specified, "openid", "profile", and "email" are used as default scopes. Google Sign-In documentation: https://developers.google.com/identity/sign-in/web/
  --http-api-prefix-path: string # Gets or sets the relative path prefix used by platform HTTP APIs. Changing this value is not recommended except for compatibility reasons.
  --issuer: string # Gets or sets the OpenID Connect Issuer URI that represents the entity which issues access tokens for this application. When using Azure Active Directory, this value is the URI of the directory tenant, e.g. https://sts.windows.net/{tenant-guid}/. This URI is a case-sensitive identifier for the token issuer. More information on OpenID Connect Discovery: http://openid.net/specs/openid-connect-discovery-1_0.html
  --microsoft-account-client-id: string # Gets or sets the OAuth 2.0 client ID that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-client-secret: string # Gets or sets the OAuth 2.0 client secret that was created for the app used for authentication. This setting is required for enabling Microsoft Account authentication. Microsoft Account OAuth documentation: https://dev.onedrive.com/auth/msa_oauth.htm
  --microsoft-account-o-auth-scopes: list<string> # Gets or sets the OAuth 2.0 scopes that will be requested as part of Microsoft Account authentication. This setting is optional. If not specified, "wl.basic" is used as the default scope. Microsoft Account Scopes and permissions documentation: https://msdn.microsoft.com/en-us/library/dn631845.aspx
  --open-id-issuer: string
  --token-refresh-extension-hours: float # Gets or sets the number of hours after session token expiration that a session token can be used to call the token refresh API. The default is 72 hours. (format: double)
  --token-store-enabled: oneof<nothing, bool> # Gets or sets a value indicating whether to durably store platform-specific security tokens obtained during login flows. This capability is disabled by default.
  --twitter-consumer-key: string # Gets or sets the OAuth 1.0a consumer key of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --twitter-consumer-secret: string # Gets or sets the OAuth 1.0a consumer secret of the Twitter application used for sign-in. This setting is required for enabling Twitter Sign-In. Twitter Sign-In documentation: https://dev.twitter.com/web/sign-in
  --unauthenticated-client-action: string@unauthenticated-client-action-completer # Gets or sets the action to take when an unauthenticated client attempts to access the app.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aadClientId, var: aad_client_id}, {name: additionalLoginParams, var: additional_login_params}, {name: allowedAudiences, var: allowed_audiences}, {name: allowedExternalRedirectUrls, var: allowed_external_redirect_urls}, {name: clientId, var: client_id}, {name: clientSecret, var: client_secret}, {name: defaultProvider, var: default_provider}, {name: enabled, var: enabled}, {name: facebookAppId, var: facebook_app_id}, {name: facebookAppSecret, var: facebook_app_secret}, {name: facebookOAuthScopes, var: facebook_o_auth_scopes}, {name: googleClientId, var: google_client_id}, {name: googleClientSecret, var: google_client_secret}, {name: googleOAuthScopes, var: google_o_auth_scopes}, {name: httpApiPrefixPath, var: http_api_prefix_path}, {name: issuer, var: issuer}, {name: microsoftAccountClientId, var: microsoft_account_client_id}, {name: microsoftAccountClientSecret, var: microsoft_account_client_secret}, {name: microsoftAccountOAuthScopes, var: microsoft_account_o_auth_scopes}, {name: openIdIssuer, var: open_id_issuer}, {name: tokenRefreshExtensionHours, var: token_refresh_extension_hours}, {name: tokenStoreEnabled, var: token_store_enabled}, {name: twitterConsumerKey, var: twitter_consumer_key}, {name: twitterConsumerSecret, var: twitter_consumer_secret}, {name: unauthenticatedClientAction, var: unauthenticated_client_action}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, aad_client_id: $aad_client_id, additional_login_params: $additional_login_params, allowed_audiences: $allowed_audiences, allowed_external_redirect_urls: $allowed_external_redirect_urls, client_id: $client_id, client_secret: $client_secret, default_provider: $default_provider, enabled: $enabled, facebook_app_id: $facebook_app_id, facebook_app_secret: $facebook_app_secret, facebook_o_auth_scopes: $facebook_o_auth_scopes, google_client_id: $google_client_id, google_client_secret: $google_client_secret, google_o_auth_scopes: $google_o_auth_scopes, http_api_prefix_path: $http_api_prefix_path, issuer: $issuer, microsoft_account_client_id: $microsoft_account_client_id, microsoft_account_client_secret: $microsoft_account_client_secret, microsoft_account_o_auth_scopes: $microsoft_account_o_auth_scopes, open_id_issuer: $open_id_issuer, token_refresh_extension_hours: $token_refresh_extension_hours, token_store_enabled: $token_store_enabled, twitter_consumer_key: $twitter_consumer_key, twitter_consumer_secret: $twitter_consumer_secret, unauthenticated_client_action: $unauthenticated_client_action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the Authentication / Authorization settings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings/list
# Returns: record<aadClientId: string, additionalLoginParams: list<string>, allowedAudiences: list<string>, allowedExternalRedirectUrls: list<string>, clientId: string, clientSecret: string, defaultProvider: string, enabled: bool, facebookAppId: string, facebookAppSecret: string, facebookOAuthScopes: list<string>, googleClientId: string, googleClientSecret: string, googleOAuthScopes: list<string>, httpApiPrefixPath: string, issuer: string, microsoftAccountClientId: string, microsoftAccountClientSecret: string, microsoftAccountOAuthScopes: list<string>, openIdIssuer: string, tokenRefreshExtensionHours: float, tokenStoreEnabled: bool, twitterConsumerKey: string, twitterConsumerSecret: string, unauthenticatedClientAction: string>
# operationId: Sites_ListSiteAuthSettingsSlot
export def "sites-list-site-auth-settings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/authsettings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates backup configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup
# Returns: record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteBackupConfigurationSlot
export def "sites-update-site-backup-configuration-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {backupSchedule?: record, databases?: list, enabled?: bool, name?: string, storageAccountUrl?: string, type: "Default"|"Clone"|"Relocation"}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the backup configuration for a web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup/list
# Returns: record<properties: record<backupSchedule: record<frequencyInterval: int, frequencyUnit: string, keepAtLeastOneBackup: bool, lastExecutionTime: string, retentionPeriodInDays: int, startTime: string>, databases: list<record>, enabled: bool, name: string, storageAccountUrl: string, type: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteBackupConfigurationSlot
export def "sites-get-site-backup-configuration-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/backup/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the connection strings associated with web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteConnectionStringsSlot
export def "sites-update-site-connection-strings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: record # Connection strings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the connection strings associated with web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteConnectionStringsSlot
export def "sites-list-site-connection-strings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/connectionstrings/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app logs configuration
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# Returns: record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteLogsConfigSlot
export def "sites-get-site-logs-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs
# Returns: record<properties: record<applicationLogs: record<azureBlobStorage: record, azureTableStorage: record, fileSystem: record>, detailedErrorMessages: record<enabled: bool>, failedRequestsTracing: record<enabled: bool>, httpLogs: record<azureBlobStorage: record, fileSystem: record>>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteLogsConfigSlot
export def "sites-update-site-logs-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {applicationLogs?: record, detailedErrorMessages?: record, failedRequestsTracing?: record, httpLogs?: record}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/logs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the meta data for web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteMetadataSlot
export def "sites-update-site-metadata-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: record # Settings
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app meta data.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata/list
# Returns: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteMetadataSlot
export def "sites-list-site-metadata-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/metadata/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the web app publishing credentials
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/publishingcredentials/list
# Returns: record<properties: record<name: string, publishingPassword: string, publishingUserName: string, scmUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSitePublishingCredentialsSlot
export def "sites-list-site-publishing-credentials-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/publishingcredentials/list"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the configuration of the web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteConfigSlot
export def "sites-get-site-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteConfigSlot
export def "sites-update-site-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web
# Returns: record<properties: record<alwaysOn: bool, apiDefinition: record<url: string>, appCommandLine: string, appSettings: list<record>, autoHealEnabled: bool, autoHealRules: record<actions: record, triggers: record>, autoSwapSlotName: string, connectionStrings: list<record>, cors: record<allowedOrigins: list>, defaultDocuments: list<string>, detailedErrorLoggingEnabled: bool, documentRoot: string, experiments: record<rampUpRules: list>, handlerMappings: list<record>, httpLoggingEnabled: bool, ipSecurityRestrictions: list<record>, javaContainer: string, javaContainerVersion: string, javaVersion: string, limits: record<maxDiskSizeInMb: int, maxMemoryInMb: int, maxPercentageCpu: float>, loadBalancing: string, localMySqlEnabled: bool, logsDirectorySizeLimit: int, managedPipelineMode: string, metadata: list<record>, netFrameworkVersion: string, nodeVersion: string, numberOfWorkers: int, phpVersion: string, publishingPassword: string, publishingUsername: string, pythonVersion: string, remoteDebuggingEnabled: bool, remoteDebuggingVersion: string, requestTracingEnabled: bool, requestTracingExpirationTime: string, scmType: string, tracingOptions: string, use32BitWorkerProcess: bool, virtualApplications: list<record>, vnetName: string, webSocketsEnabled: bool>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteConfigSlot
export def "sites-create-or-update-site-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {alwaysOn?: bool, apiDefinition?: record, appCommandLine?: string, appSettings?: list, autoHealEnabled?: bool, autoHealRules?: record, autoSwapSlotName?: string, connectionStrings?: list, cors?: record, defaultDocuments?: list<string>, detailedErrorLoggingEnabled?: bool, documentRoot?: string, experiments?: record, handlerMappings?: list, httpLoggingEnabled?: bool, ipSecurityRestrictions?: list, javaContainer?: string, javaContainerVersion?: string, javaVersion?: string, limits?: record, ... (22 more fields)}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/config/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetDeploymentsSlot
export def "sites-get-deployments-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# Returns: record
# operationId: Sites_DeleteDeploymentSlot
export def "sites-delete-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetDeploymentSlot
export def "sites-get-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateDeploymentSlot
export def "sites-create-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id (spec name: id)
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: body_id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, id: $id, api_version: $api_version, properties: $properties, body_id: $body_id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get web app hostname bindings
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteHostNameBindingsSlot
export def "sites-get-site-host-name-bindings-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a host name binding
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# Returns: record
# operationId: Sites_DeleteSiteHostNameBindingSlot
export def "sites-delete-site-host-name-binding-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, host_name: $host_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get web app binding for a hostname
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# Returns: record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteHostNameBindingSlot
export def "sites-get-site-host-name-binding-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, host_name: $host_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a web app hostname binding
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}
# Returns: record<properties: record<azureResourceName: string, azureResourceType: string, customHostNameDnsRecordType: string, domainId: string, hostNameType: string, name: string, siteName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteHostNameBindingSlot
export def "sites-create-or-update-site-host-name-binding-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  host_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {azureResourceName?: string, azureResourceType?: "Website"|"TrafficManager", customHostNameDnsRecordType?: "CName"|"A", domainId?: string, hostNameType?: "Verified"|"Managed", name?: string, siteName?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hostNameBindings/{hostName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: hostName, var: host_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, host_name: $host_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves all BizTalk Hybrid Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_ListSiteRelayServiceConnectionsSlot
export def "sites-list-site-relay-service-connections-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the association to a BizTalk Hybrid Connection, identified by its entity name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# Returns: record
# operationId: Sites_DeleteSiteRelayServiceConnectionSlot
export def "sites-delete-site-relay-service-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, entity_name: $entity_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a BizTalk Hybrid Connection identified by its entity name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteRelayServiceConnectionSlot
export def "sites-get-site-relay-service-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, entity_name: $entity_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteRelayServiceConnectionSlot
export def "sites-update-site-relay-service-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, entity_name: $entity_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new association to a BizTalk Hybrid Connection, or updates an existing one.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}
# Returns: record<properties: record<biztalkUri: string, entityConnectionString: string, entityName: string, hostname: string, port: int, resourceConnectionString: string, resourceType: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteRelayServiceConnectionSlot
export def "sites-create-or-update-site-relay-service-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  entity_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {biztalkUri?: string, entityConnectionString?: string, entityName?: string, hostname?: string, port?: int, resourceConnectionString?: string, resourceType?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/hybridconnection/{entityName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: entityName, var: entity_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, entity_name: $entity_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all instance of a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteInstanceIdentifiersSlot
export def "sites-get-site-instance-identifiers-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# List deployments
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetInstanceDeploymentsSlot
export def "sites-get-instance-deployments-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: instanceId, var: instance_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, instance_id: $instance_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete the deployment
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# Returns: record
# operationId: Sites_DeleteInstanceDeploymentSlot
export def "sites-delete-instance-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, instance_id: $instance_id, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the deployment
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetInstanceDeploymentSlot
export def "sites-get-instance-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, instance_id: $instance_id, id: $id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create a deployment
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}
# Returns: record<properties: record<active: bool, author: string, author_email: string, deployer: string, details: string, end_time: string, id: string, message: string, start_time: string, status: int>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateInstanceDeploymentSlot
export def "sites-create-instance-deployment-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  instance_id: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {active?: bool, author?: string, author_email?: string, deployer?: string, details?: string, end_time?: string, id?: string, message?: string, start_time?: string, status?: int}
  --body-id: string # Resource Id (spec name: id)
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/instances/{instanceId}/deployments/{id}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: instanceId, var: instance_id}, {name: id, var: id}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: body_id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, instance_id: $instance_id, id: $id, api_version: $api_version, properties: $properties, body_id: $body_id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new web app or modifies an existing web app.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/iscloneable
# Returns: record<blockingCharacteristics: table<description: string, name: string>, blockingFeatures: table<description: string, name: string>, result: string, unsupportedFeatures: table<description: string, name: string>>
# operationId: Sites_IsSiteCloneableSlot
export def "sites-is-site-cloneable-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/iscloneable"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets metric definitions for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metricdefinitions
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSiteMetricDefinitionsSlot
export def "sites-get-site-metric-definitions-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metricdefinitions"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets metrics for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metrics
# Returns: record<nextLink: string, value: table<endTime: string, metricValues: list, name: record, properties: list, resourceId: string, startTime: string, timeGrain: string, unit: string>>
# operationId: Sites_GetSiteMetricsSlot
export def "sites-get-site-metrics-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --details: oneof<nothing, bool> # If true, metric details are included in response
  --filter: string # Return only usages/metrics specified in the filter. Filter conforms to odata syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/metrics"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: details, var: details}, {name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, details: $details, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a view of all network features in use on this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkFeatures/{view}
# Returns: record<properties: record<hybridConnections: list<record>, virtualNetworkConnection: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, virtualNetworkName: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteNetworkFeaturesSlot
export def "sites-get-site-network-features-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  view: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/networkFeatures/{view}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: view, var: view}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, view: $view, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Generates new random app publishing password
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/newpassword
# Returns: record
# operationId: Sites_GenerateNewSitePublishingPasswordSlot
export def "sites-generate-new-site-publishing-password-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/newpassword"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the operation for a web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/operationresults/{operationId}
# Returns: record
# operationId: Sites_GetSiteOperationSlot
export def "sites-get-site-operation-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/operationresults/{operationId}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: operationId, var: operation_id}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, operation_id: $operation_id, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons
#
# Returns: record
# operationId: Sites_ListSitePremierAddOnsSlot
export def "sites-list-site-premier-add-ons-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_DeleteSitePremierAddOnSlot
export def "sites-delete-site-premier-add-on-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, premier_add_on_name: $premier_add_on_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_GetSitePremierAddOnSlot
export def "sites-get-site-premier-add-on-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, premier_add_on_name: $premier_add_on_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}
#
# Returns: record
# operationId: Sites_AddSitePremierAddOnSlot
export def "sites-add-site-premier-add-on-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  premier_add_on_name: string
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
  --api-version: string # API Version (required)
  --location: string # Geo region resource belongs to e.g. SouthCentralUS, SouthEastAsia
  --plan: record # The plan object in an ARM, represents a marketplace plan — shape: {name?: string, product?: string, promotionCode?: string, publisher?: string, version?: string}
  --properties: record
  --sku: record # Describes a sku for a scalable resource — shape: {capacity?: int, family?: string, name?: string, size?: string, tier?: string}
  --tags: record # Tags associated with resource
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/premieraddons/{premierAddOnName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: premierAddOnName, var: premier_add_on_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: location, var: location}, {name: plan, var: plan}, {name: properties, var: properties}, {name: sku, var: sku}, {name: tags, var: tags}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, premier_add_on_name: $premier_add_on_name, api_version: $api_version, location: $location, plan: $plan, properties: $properties, sku: $sku, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the publishing profile for web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publishxml
# Returns: binary
# operationId: Sites_ListSitePublishingProfileXmlSlot
export def "sites-list-site-publishing-profile-xml-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --format: string # Name of the format. Valid values are: FileZilla3 WebDeploy -- default Ftp
]: any -> any {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/publishxml"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: format, var: format}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Recovers a deleted web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/recover
# Returns: record<properties: record<availabilityState: string, clientAffinityEnabled: bool, clientCertEnabled: bool, cloningInfo: record<appSettingsOverrides: record, cloneCustomHostNames: bool, cloneSourceControl: bool, configureLoadBalancing: bool, correlationId: string, hostingEnvironment: string, overwrite: bool, sourceWebAppId: string, trafficManagerProfileId: string, trafficManagerProfileName: string>, containerSize: int, defaultHostName: string, enabled: bool, enabledHostNames: list<string>, gatewaySiteName: string, hostNameSslStates: list<record>, hostNames: list<string>, hostNamesDisabled: bool, hostingEnvironmentProfile: record<id: string, name: string, type: string>, isDefaultContainer: bool, lastModifiedTimeUtc: string, maxNumberOfWorkers: int, microService: string, name: string, outboundIpAddresses: string, premiumAppDeployed: bool, repositorySiteName: string, resourceGroup: string, scmSiteAlsoStopped: bool, serverFarmId: string, siteConfig: record<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>, state: string, targetSwapSlot: string, trafficManagerHostNames: list<string>, usageState: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_RecoverSiteSlot
export def "sites-recover-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --recover-config: oneof<nothing, bool> # If true, then the website's configuration will be reverted to its state at SnapshotTime
  --site-name: string # [Optional] Destination web app name into which web app should be recovered. This is case when new web app should be created instead.
  --slot-name: string # [Optional] Destination web app slot name into which web app should be recovered
  --snapshot-time: string # Point in time in which the site recover should be attempted. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/recover"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: recoverConfig, var: recover_config}, {name: siteName, var: site_name}, {name: slotName, var: slot_name}, {name: snapshotTime, var: snapshot_time}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, recover_config: $recover_config, site_name: $site_name, slot_name: $slot_name, snapshot_time: $snapshot_time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resets the configuration settings of the current slot if they were previously modified by calling ApplySlotConfig API
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/resetSlotConfig
# Returns: record
# operationId: Sites_ResetSlotConfigSlot
export def "sites-reset-slot-config-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/resetSlotConfig"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Restarts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restart
# Returns: record
# operationId: Sites_RestartSiteSlot
export def "sites-restart-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --soft-restart: oneof<nothing, bool> # Soft restart applies the configuration settings and restarts the app if necessary. Hard restart always restarts and reprovisions the app
  --synchronous: oneof<nothing, bool> # If true then the API will block until the app has been restarted
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/restart"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: softRestart, var: soft_restart}, {name: synchronous, var: synchronous}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, soft_restart: $soft_restart, synchronous: $synchronous, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the difference in configuration settings between two web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsdiffs
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSlotsDifferencesSlot
export def "sites-get-slots-differences-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsdiffs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Swaps web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsswap
# Returns: record
# operationId: Sites_SwapSlotsSlot
export def "sites-swap-slots-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/slotsswap"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all Snapshots to the user.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshots
# Returns: record
# operationId: Sites_GetSiteSnapshotsSlot
export def "sites-get-site-snapshots-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/snapshots"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete source control configuration of web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# Returns: record
# operationId: Sites_DeleteSiteSourceControlSlot
export def "sites-delete-site-source-control-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the source control configuration of web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteSourceControlSlot
export def "sites-get-site-source-control-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the source control configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteSourceControlSlot
export def "sites-update-site-source-control-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the source control configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteSourceControlSlot
export def "sites-create-or-update-site-source-control-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Starts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/start
# Returns: record
# operationId: Sites_StartSiteSlot
export def "sites-start-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stops web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stop
# Returns: record
# operationId: Sites_StopSiteSlot
export def "sites-stop-site-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sync
#
# Returns: record
# operationId: Sites_SyncSiteRepositorySlot
export def "sites-sync-site-repository-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/sync"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the quota usage numbers for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/usages
# Returns: record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>
# operationId: Sites_GetSiteUsagesSlot
export def "sites-get-site-usages-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --filter: string # Return only usages specified in the filter. Filter is specified by using OData syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a list of all Virtual Network Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections
# Returns: table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteVNETConnectionsSlot
export def "sites-get-site-vnet-connections-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the specified Virtual Network Connection association from this web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# Returns: record
# operationId: Sites_DeleteSiteVNETConnectionSlot
export def "sites-delete-site-vnet-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a specific Virtual Network Connection associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteVNETConnectionSlot
export def "sites-get-site-vnet-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteVNETConnectionSlot
export def "sites-update-site-vnet-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteVNETConnectionSlot
export def "sites-create-or-update-site-vnet-connection-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Virtual Network connection gateway associated with this web app and virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record
# operationId: Sites_GetSiteVnetGatewaySlot
export def "sites-get-site-vnet-gateway-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Virtual Network Gateway.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteVNETConnectionGatewaySlot
export def "sites-update-site-vnet-connection-gateway-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Virtual Network Gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteVNETConnectionGatewaySlot
export def "sites-create-or-update-site-vnet-connection-gateway-slot" [
  subscription_id: string
  resource_group_name: string
  name: string
  slot: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slots/{slot}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: slot, var: slot}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, slot: $slot, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the difference in configuration settings between two web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsdiffs
# Returns: record<nextLink: string, value: table<properties: record, id: string, kind: string, location: string, name: string, tags: record, type: string>>
# operationId: Sites_GetSlotsDifferencesFromProduction
export def "sites-get-slots-differences-from-production" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsdiffs"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Swaps web app slots
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsswap
# Returns: record
# operationId: Sites_SwapSlotWithProduction
export def "sites-swap-slot-with-production" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --preserve-vnet: oneof<nothing, bool> # Get or set the flag indicating it should preserve VNet to the slot during swap
  --target-slot: string # Set the destination deployment slot during swap operation
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/slotsswap"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: preserveVnet, var: preserve_vnet}, {name: targetSlot, var: target_slot}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 202]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, preserve_vnet: $preserve_vnet, target_slot: $target_slot
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all Snapshots to the user.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/snapshots
# Returns: record
# operationId: Sites_GetSiteSnapshots
export def "sites-get-site-snapshots" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/snapshots"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete source control configuration of web app
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# Returns: record
# operationId: Sites_DeleteSiteSourceControl
export def "sites-delete-site-source-control" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get the source control configuration of web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteSourceControl
export def "sites-get-site-source-control" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the source control configuration of web app
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteSourceControl
export def "sites-update-site-source-control" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update the source control configuration of web app
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web
# Returns: record<properties: record<branch: string, deploymentRollbackEnabled: bool, isManualIntegration: bool, isMercurial: bool, repoUrl: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteSourceControl
export def "sites-create-or-update-site-source-control" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
  --properties: any # shape: {branch?: string, deploymentRollbackEnabled?: bool, isManualIntegration?: bool, isMercurial?: bool, repoUrl?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sourcecontrols/web"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 201]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Starts web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/start
# Returns: record
# operationId: Sites_StartSite
export def "sites-start-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/start"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Stops web app
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/stop
# Returns: record
# operationId: Sites_StopSite
export def "sites-stop-site" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/stop"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sync
#
# Returns: record
# operationId: Sites_SyncSiteRepository
export def "sites-sync-site-repository" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/sync"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the quota usage numbers for web app
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/usages
# Returns: record<nextLink: string, value: table<currentValue: int, limit: int, name: record, nextResetTime: string, unit: string>>
# operationId: Sites_GetSiteUsages
export def "sites-get-site-usages" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer-1 # Response content type
  --filter: string # Return only usages specified in the filter. Filter is specified by using OData syntax. Example: $filter=(name.value eq 'Metric1' or name.value eq 'Metric2') and startTime eq '2014-01-01T00:00:00Z' and endTime eq '2014-12-31T23:59:59Z' and timeGrain eq duration'[Hour|Minute|Day]'.
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/usages"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: "$filter", var: filter}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, filter: $filter, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a list of all Virtual Network Connections associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections
# Returns: table<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteVNETConnections
export def "sites-get-site-vnet-connections" [
  subscription_id: string
  resource_group_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Removes the specified Virtual Network Connection association from this web app.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# Returns: record
# operationId: Sites_DeleteSiteVNETConnection
export def "sites-delete-site-vnet-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a specific Virtual Network Connection associated with this web app.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_GetSiteVNETConnection
export def "sites-get-site-vnet-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteVNETConnection
export def "sites-update-site-vnet-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Adds a Virtual Network Connection or updates it's properties.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}
# Returns: record<properties: record<certBlob: string, certThumbprint: string, dnsServers: string, resyncRequired: bool, routes: list<record>, vnetResourceId: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteVNETConnection
export def "sites-create-or-update-site-vnet-connection" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {certBlob?: string, certThumbprint?: string, dnsServers?: string, resyncRequired?: bool, routes?: list, vnetResourceId?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a Virtual Network connection gateway associated with this web app and virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record
# operationId: Sites_GetSiteVnetGateway
export def "sites-get-site-vnet-gateway" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Virtual Network Gateway.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_UpdateSiteVNETConnectionGateway
export def "sites-update-site-vnet-connection-gateway" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the Virtual Network Gateway.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}
# Returns: record<properties: record<vnetName: string, vpnPackageUri: string>, id: string, kind: string, location: string, name: string, tags: record, type: string>
# operationId: Sites_CreateOrUpdateSiteVNETConnectionGateway
export def "sites-create-or-update-site-vnet-connection-gateway" [
  subscription_id: string
  resource_group_name: string
  name: string
  vnet_name: string
  gateway_name: string
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
  --api-version: string # API Version (required)
  --properties: any # shape: {vnetName?: string, vpnPackageUri?: string}
  --id: string # Resource Id
  --kind: string # Kind of resource
  location: string # Resource Location
  --body-name: string # Resource Name (spec name: name)
  --tags: record # Resource tags
  --type: string # Resource type
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{name}/virtualNetworkConnections/{vnetName}/gateways/{gatewayName}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: name, var: name}, {name: vnetName, var: vnet_name}, {name: gatewayName, var: gateway_name}]
    query: [{name: api-version, var: api_version, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: properties, var: properties}, {name: id, var: id}, {name: kind, var: kind}, {name: location, var: location}, {name: name, var: body_name}, {name: tags, var: tags}, {name: type, var: type}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, name: $name, vnet_name: $vnet_name, gateway_name: $gateway_name, api_version: $api_version, properties: $properties, id: $id, kind: $kind, location: $location, body_name: $body_name, tags: $tags, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the list of past recommendations optionally specified by the time range.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendationHistory
# Returns: table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>
# operationId: Recommendations_GetRecommendationHistoryForSite
export def "recommendations-get-recommendation-history-for-site" [
  subscription_id: string
  resource_group_name: string
  site_name: string
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
  --start-time: string # The start time of a time range to query, e.g. $filter=startTime eq '2015-01-01T00:00:00Z' and endTime eq '2015-01-02T00:00:00Z'
  --end-time: string # The end time of a time range to query, e.g. $filter=startTime eq '2015-01-01T00:00:00Z' and endTime eq '2015-01-02T00:00:00Z'
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendationHistory"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: siteName, var: site_name}]
    query: [{name: startTime, var: start_time}, {name: endTime, var: end_time}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, site_name: $site_name, start_time: $start_time, end_time: $end_time, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of recommendations associated with the specified web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations
# Returns: table<actionName: string, channels: string, creationTime: string, displayName: string, enabled: int, endTime: string, level: string, message: string, nextNotificationTime: string, notificationExpirationTime: string, notifiedTime: string, recommendationId: string, resourceId: string, resourceScope: string, ruleName: string, score: float, startTime: string, tags: list<string>>
# operationId: Recommendations_GetRecommendedRulesForSite
export def "recommendations-get-recommended-rules-for-site" [
  subscription_id: string
  resource_group_name: string
  site_name: string
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
  --featured: oneof<nothing, bool> # If set, this API returns only the most critical recommendation among the others. Otherwise this API returns all recommendations available
  --site-sku: string # The name of site SKU.
  --num-slots: int # The number of site slots associated to the site (format: int32)
  --api-version: string # API Version (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: siteName, var: site_name}]
    query: [{name: featured, var: featured}, {name: siteSku, var: site_sku}, {name: numSlots, var: num_slots}, {name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, site_name: $site_name, featured: $featured, site_sku: $site_sku, num_slots: $num_slots, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the detailed properties of the recommendation object for the specified web site.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations/{name}
# Returns: record<actionName: string, channels: string, description: string, displayName: string, enabled: int, level: string, message: string, name: string, recommendationId: string, tags: list<string>>
# operationId: Recommendations_GetRuleDetailsBySiteName
export def "recommendations-get-rule-details-by-site-name" [
  subscription_id: string
  resource_group_name: string
  site_name: string
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
  --accept: string@accept-completer # Response content type
  --api-version: string # API Version (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Web/sites/{siteName}/recommendations/{name}"
    path_params: [{name: subscriptionId, var: subscription_id}, {name: resourceGroupName, var: resource_group_name}, {name: siteName, var: site_name}, {name: name, var: name}]
    query: [{name: api-version, var: api_version, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    subscription_id: $subscription_id, resource_group_name: $resource_group_name, site_name: $site_name, name: $name, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
