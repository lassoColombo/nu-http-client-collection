# Auto-generated client for CRM API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/crm/9.3.0/openapi.json
# Auth: --token flag or $env.CRM_API_TOKEN

const CLIENT = {
  base_url: "https://unify.apideck.com"
  token_env_var: "CRM_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: x-apideck-app-id, in: header, header_name: x-apideck-app-id, prefix: ""}
    {name: x-apideck-consumer-id, in: header, header_name: x-apideck-consumer-id, prefix: ""}
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer" "x-apideck-app-id" "x-apideck-consumer-id"] }

# Completers for enum parameters
def show-as-completer [] { ["busy" "free"] }
def type-completer [] { ["call" "deadline" "email" "meeting" "note" "other" "send-letter" "send-quote" "task"] }
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTC" "BTN" "BWP" "BYR" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "ETH" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LVL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRC" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "UNKNOWN_CURRENCY" "USD" "USN" "USS" "UYI" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XTS" "XXX" "YER" "ZAR" "ZMK" "ZMW"] }
def gender-completer [] { ["female" "male" "unisex"] }
def type-completer-1 [] { ["customer" "employee" "personal" "supplier"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    activities-all: "record<data: table<account_id: string, activity_date: string, activity_datetime: string, all_day_event: bool, archived: bool, asset_id: string, attendees: list, campaign_id: string, case_id: string, child: bool, company_id: string, contact_id: string, contract_id: string, created_at: string, created_by: string, custom_fields: list, custom_object_id: string, deleted: bool, description: string, done: bool, downstream_id: string, duration_minutes: int, duration_seconds: int, end_date: string, end_datetime: string, event_sub_type: string, group_event: bool, group_event_type: string, id: string, lead_id: string, location: string, location_address: record, note: string, opportunity_id: string, owner_id: string, private: bool, product_id: string, recurrent: bool, reminder_datetime: string, reminder_set: bool, show_as: string, solution_id: string, start_datetime: string, title: string, type: string, updated_at: string, updated_by: string, user_id: string, video_conference_id: string, video_conference_url: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    activities-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    activities-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    activities-one: "record<data: record<account_id: string, activity_date: string, activity_datetime: string, all_day_event: bool, archived: bool, asset_id: string, attendees: list<record>, campaign_id: string, case_id: string, child: bool, company_id: string, contact_id: string, contract_id: string, created_at: string, created_by: string, custom_fields: list<record>, custom_object_id: string, deleted: bool, description: string, done: bool, downstream_id: string, duration_minutes: int, duration_seconds: int, end_date: string, end_datetime: string, event_sub_type: string, group_event: bool, group_event_type: string, id: string, lead_id: string, location: string, location_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, note: string, opportunity_id: string, owner_id: string, private: bool, product_id: string, recurrent: bool, reminder_datetime: string, reminder_set: bool, show_as: string, solution_id: string, start_datetime: string, title: string, type: string, updated_at: string, updated_by: string, user_id: string, video_conference_id: string, video_conference_url: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    activities-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    companies-all: "record<data: table<abn_branch: string, abn_or_tfn: string, acn: string, addresses: list, annual_revenue: string, bank_accounts: list, birthday: string, created_at: string, created_by: string, currency: string, custom_fields: list, deleted: bool, description: string, emails: list, fax: string, first_name: string, id: string, image: string, industry: string, interaction_count: int, last_activity_at: string, last_name: string, name: string, number_of_employees: string, owner_id: string, ownership: string, parent_id: string, payee_number: string, phone_numbers: list, read_only: bool, row_type: record, sales_tax_number: string, salutation: string, social_links: list, status: string, tags: list, updated_at: string, updated_by: string, vat_number: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    companies-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    companies-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    companies-one: "record<data: record<abn_branch: string, abn_or_tfn: string, acn: string, addresses: list<record>, annual_revenue: string, bank_accounts: list<record>, birthday: string, created_at: string, created_by: string, currency: string, custom_fields: list<record>, deleted: bool, description: string, emails: list<record>, fax: string, first_name: string, id: string, image: string, industry: string, interaction_count: int, last_activity_at: string, last_name: string, name: string, number_of_employees: string, owner_id: string, ownership: string, parent_id: string, payee_number: string, phone_numbers: list<record>, read_only: bool, row_type: record<id: string, name: string>, sales_tax_number: string, salutation: string, social_links: list<record>, status: string, tags: list<string>, updated_at: string, updated_by: string, vat_number: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    companies-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    contacts-all: "record<data: table<active: bool, addresses: list, birthday: string, company_id: string, company_name: string, created_at: string, current_balance: float, custom_fields: list, department: string, description: string, email_domain: string, emails: list, fax: string, first_call_at: string, first_email_at: string, first_name: string, gender: string, id: string, image: string, language: string, last_activity_at: string, last_name: string, lead_id: string, lead_source: string, middle_name: string, name: string, owner_id: string, phone_numbers: list, photo_url: string, prefix: string, social_links: list, status: string, suffix: string, tags: list, title: string, type: string, updated_at: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    contacts-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    contacts-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    contacts-one: "record<data: record<active: bool, addresses: list<record>, birthday: string, company_id: string, company_name: string, created_at: string, current_balance: float, custom_fields: list<record>, department: string, description: string, email_domain: string, emails: list<record>, fax: string, first_call_at: string, first_email_at: string, first_name: string, gender: string, id: string, image: string, language: string, last_activity_at: string, last_name: string, lead_id: string, lead_source: string, middle_name: string, name: string, owner_id: string, phone_numbers: list<record>, photo_url: string, prefix: string, social_links: list<record>, status: string, suffix: string, tags: list<string>, title: string, type: string, updated_at: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    contacts-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    leads-all: "record<data: table<addresses: list, company_id: string, company_name: string, contact_id: string, created_at: string, currency: string, custom_fields: list, description: string, emails: list, fax: string, first_name: string, id: string, language: string, last_name: string, lead_source: string, monetary_amount: float, name: string, owner_id: string, phone_numbers: list, prefix: string, social_links: list, status: string, tags: list, title: string, updated_at: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    leads-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    leads-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    leads-one: "record<data: record<addresses: list<record>, company_id: string, company_name: string, contact_id: string, created_at: string, currency: string, custom_fields: list<record>, description: string, emails: list<record>, fax: string, first_name: string, id: string, language: string, last_name: string, lead_source: string, monetary_amount: float, name: string, owner_id: string, phone_numbers: list<record>, prefix: string, social_links: list<record>, status: string, tags: list<string>, title: string, updated_at: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>"
    leads-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    notes-all: "record<data: table<active: bool, company_id: string, contact_id: string, content: string, created_at: string, created_by: string, id: string, lead_id: string, opportunity_id: string, owner_id: string, title: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    notes-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    notes-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    notes-one: "record<data: record<active: bool, company_id: string, contact_id: string, content: string, created_at: string, created_by: string, id: string, lead_id: string, opportunity_id: string, owner_id: string, title: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    notes-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    opportunities-all: "record<data: table<close_date: string, company_id: string, company_name: string, contact_id: string, contact_ids: list, created_at: string, created_by: string, currency: string, custom_fields: list, date_last_contacted: string, date_lead_created: string, date_stage_changed: string, deleted: bool, description: string, expected_revenue: float, id: string, interaction_count: float, last_activity_at: string, lead_id: string, lead_source: string, loss_reason: string, loss_reason_id: string, monetary_amount: float, owner_id: string, pipeline_id: string, pipeline_stage_id: string, primary_contact_id: string, priority: string, source_id: string, stage_last_changed_at: string, status: string, status_id: string, tags: list, title: string, type: string, updated_at: string, updated_by: string, win_probability: float, won_reason: string, won_reason_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    opportunities-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    opportunities-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    opportunities-one: "record<data: record<close_date: string, company_id: string, company_name: string, contact_id: string, contact_ids: list<string>, created_at: string, created_by: string, currency: string, custom_fields: list<record>, date_last_contacted: string, date_lead_created: string, date_stage_changed: string, deleted: bool, description: string, expected_revenue: float, id: string, interaction_count: float, last_activity_at: string, lead_id: string, lead_source: string, loss_reason: string, loss_reason_id: string, monetary_amount: float, owner_id: string, pipeline_id: string, pipeline_stage_id: string, primary_contact_id: string, priority: string, source_id: string, stage_last_changed_at: string, status: string, status_id: string, tags: list<string>, title: string, type: string, updated_at: string, updated_by: string, win_probability: float, won_reason: string, won_reason_id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    opportunities-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    pipelines-all: "record<data: table<active: bool, archived: bool, created_at: string, currency: string, display_order: int, id: string, name: string, stages: list, updated_at: string, win_probability_enabled: bool>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    pipelines-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    pipelines-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    pipelines-one: "record<data: record<active: bool, archived: bool, created_at: string, currency: string, display_order: int, id: string, name: string, stages: list<record>, updated_at: string, win_probability_enabled: bool>, operation: string, resource: string, service: string, status: string, status_code: int>"
    pipelines-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    users-all: "record<data: table<addresses: list, company_name: string, created_at: string, department: string, description: string, division: string, emails: list, employee_number: string, first_name: string, id: string, image: string, language: string, last_name: string, parent_id: string, password: string, phone_numbers: list, status: string, title: string, updated_at: string, username: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>"
    users-add: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    users-delete: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    users-one: "record<data: record<addresses: list<record>, company_name: string, created_at: string, department: string, description: string, division: string, emails: list<record>, employee_number: string, first_name: string, id: string, image: string, language: string, last_name: string, parent_id: string, password: string, phone_numbers: list<record>, status: string, title: string, updated_at: string, username: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
    users-update: "record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["activities-all" "activities-add" "activities-delete" "activities-one" "activities-update" "companies-all" "companies-add" "companies-delete" "companies-one" "companies-update" "contacts-all" "contacts-add" "contacts-delete" "contacts-one" "contacts-update" "leads-all" "leads-add" "leads-delete" "leads-one" "leads-update" "notes-all" "notes-add" "notes-delete" "notes-one" "notes-update" "opportunities-all" "opportunities-add" "opportunities-delete" "opportunities-one" "opportunities-update" "pipelines-all" "pipelines-add" "pipelines-delete" "pipelines-one" "pipelines-update" "users-all" "users-add" "users-delete" "users-one" "users-update" "commands"] | sort) } | get name | first)
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

# List activities
#
# GET /crm/activities
# Returns: record<data: table<account_id: string, activity_date: string, activity_datetime: string, all_day_event: bool, archived: bool, asset_id: string, attendees: list, campaign_id: string, case_id: string, child: bool, company_id: string, contact_id: string, contract_id: string, created_at: string, created_by: string, custom_fields: list, custom_object_id: string, deleted: bool, description: string, done: bool, downstream_id: string, duration_minutes: int, duration_seconds: int, end_date: string, end_datetime: string, event_sub_type: string, group_event: bool, group_event_type: string, id: string, lead_id: string, location: string, location_address: record, note: string, opportunity_id: string, owner_id: string, private: bool, product_id: string, recurrent: bool, reminder_datetime: string, reminder_set: bool, show_as: string, solution_id: string, start_datetime: string, title: string, type: string, updated_at: string, updated_by: string, user_id: string, video_conference_id: string, video_conference_url: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: activitiesAll
export def "activities-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {updated_since: 2020-09-30T07:43:32.000Z})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/activities"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create activity
#
# POST /crm/activities
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: activitiesAdd
export def "activities-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account-id: string # nullable, e.g. 12345
  --activity-date: string # nullable, e.g. 2021-05-01
  --activity-datetime: string # nullable, e.g. 2021-05-01T12:00:00.000Z
  --all-day-event: oneof<nothing, bool> # e.g. false
  --archived: oneof<nothing, bool> # e.g. false
  --asset-id: string # nullable, e.g. 12345
  --attendees: list # item shape: {email_address?: string, first_name?: string, is_organizer?: bool, last_name?: string, middle_name?: string, name?: string, prefix?: string, status?: "accepted"|"tentative"|"declined", suffix?: string}
  --campaign-id: string # nullable, e.g. 12345
  --case-id: string # nullable, e.g. 12345
  --child: oneof<nothing, bool> # e.g. false
  --company-id: string # nullable, e.g. 12345
  --contact-id: string # nullable, e.g. 12345
  --contract-id: string # nullable, e.g. 12345
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --custom-object-id: string # nullable, e.g. 12345
  --deleted: oneof<nothing, bool> # e.g. false
  --description: string # nullable, e.g. More info about the meeting
  --done: oneof<nothing, bool> # Whether the Activity is done or not (e.g. false)
  --duration-seconds: int # nullable, e.g. 1800
  --end-date: string # nullable, e.g. 2021-05-01
  --end-datetime: string # nullable, e.g. 2021-05-01T12:30:00.000Z
  --event-sub-type: string # nullable, e.g. debrief
  --group-event: oneof<nothing, bool> # e.g. true
  --group-event-type: string # nullable, e.g. Proposed
  --lead-id: string # nullable, e.g. 12345
  --location: string # nullable, e.g. Space
  --location-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --note: string # nullable, e.g. An internal note about the meeting
  --opportunity-id: string # nullable, e.g. 12345
  --owner-id: string # nullable, e.g. 12345
  --private: oneof<nothing, bool> # e.g. true
  --product-id: string # nullable, e.g. 12345
  --recurrent: oneof<nothing, bool> # e.g. false
  --reminder-datetime: string # nullable, e.g. 2021-05-01T17:00:00.000Z
  --reminder-set: oneof<nothing, bool> # nullable, e.g. false
  --show-as: string@show-as-completer # e.g. busy
  --solution-id: string # nullable, e.g. 12345
  --start-datetime: string # nullable, e.g. 2021-05-01T12:00:00.000Z
  --title: string # nullable, e.g. Meeting
  type: string@type-completer # e.g. meeting
  --user-id: string # nullable, e.g. 12345
  --video-conference-id: string # e.g. zoom:88120759396
  --video-conference-url: string # e.g. https://us02web.zoom.us/j/88120759396
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/activities"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: activity_date, var: activity_date}, {name: activity_datetime, var: activity_datetime}, {name: all_day_event, var: all_day_event}, {name: archived, var: archived}, {name: asset_id, var: asset_id}, {name: attendees, var: attendees}, {name: campaign_id, var: campaign_id}, {name: case_id, var: case_id}, {name: child, var: child}, {name: company_id, var: company_id}, {name: contact_id, var: contact_id}, {name: contract_id, var: contract_id}, {name: custom_fields, var: custom_fields}, {name: custom_object_id, var: custom_object_id}, {name: deleted, var: deleted}, {name: description, var: description}, {name: done, var: done}, {name: duration_seconds, var: duration_seconds}, {name: end_date, var: end_date}, {name: end_datetime, var: end_datetime}, {name: event_sub_type, var: event_sub_type}, {name: group_event, var: group_event}, {name: group_event_type, var: group_event_type}, {name: lead_id, var: lead_id}, {name: location, var: location}, {name: location_address, var: location_address}, {name: note, var: note}, {name: opportunity_id, var: opportunity_id}, {name: owner_id, var: owner_id}, {name: private, var: private}, {name: product_id, var: product_id}, {name: recurrent, var: recurrent}, {name: reminder_datetime, var: reminder_datetime}, {name: reminder_set, var: reminder_set}, {name: show_as, var: show_as}, {name: solution_id, var: solution_id}, {name: start_datetime, var: start_datetime}, {name: title, var: title}, {name: type, var: type}, {name: user_id, var: user_id}, {name: video_conference_id, var: video_conference_id}, {name: video_conference_url, var: video_conference_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account_id: $account_id, activity_date: $activity_date, activity_datetime: $activity_datetime, all_day_event: $all_day_event, archived: $archived, asset_id: $asset_id, attendees: $attendees, campaign_id: $campaign_id, case_id: $case_id, child: $child, company_id: $company_id, contact_id: $contact_id, contract_id: $contract_id, custom_fields: $custom_fields, custom_object_id: $custom_object_id, deleted: $deleted, description: $description, done: $done, duration_seconds: $duration_seconds, end_date: $end_date, end_datetime: $end_datetime, event_sub_type: $event_sub_type, group_event: $group_event, group_event_type: $group_event_type, lead_id: $lead_id, location: $location, location_address: $location_address, note: $note, opportunity_id: $opportunity_id, owner_id: $owner_id, private: $private, product_id: $product_id, recurrent: $recurrent, reminder_datetime: $reminder_datetime, reminder_set: $reminder_set, show_as: $show_as, solution_id: $solution_id, start_datetime: $start_datetime, title: $title, type: $type, user_id: $user_id, video_conference_id: $video_conference_id, video_conference_url: $video_conference_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete activity
#
# DELETE /crm/activities/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: activitiesDelete
export def "activities-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/activities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get activity
#
# GET /crm/activities/{id}
# Returns: record<data: record<account_id: string, activity_date: string, activity_datetime: string, all_day_event: bool, archived: bool, asset_id: string, attendees: list<record>, campaign_id: string, case_id: string, child: bool, company_id: string, contact_id: string, contract_id: string, created_at: string, created_by: string, custom_fields: list<record>, custom_object_id: string, deleted: bool, description: string, done: bool, downstream_id: string, duration_minutes: int, duration_seconds: int, end_date: string, end_datetime: string, event_sub_type: string, group_event: bool, group_event_type: string, id: string, lead_id: string, location: string, location_address: record<city: string, contact_name: string, country: string, county: string, email: string, fax: string, id: string, latitude: string, line1: string, line2: string, line3: string, line4: string, longitude: string, name: string, phone_number: string, postal_code: string, row_version: string, salutation: string, state: string, street_number: string, string: string, type: string, website: string>, note: string, opportunity_id: string, owner_id: string, private: bool, product_id: string, recurrent: bool, reminder_datetime: string, reminder_set: bool, show_as: string, solution_id: string, start_datetime: string, title: string, type: string, updated_at: string, updated_by: string, user_id: string, video_conference_id: string, video_conference_url: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: activitiesOne
export def "activities-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/activities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update activity
#
# PATCH /crm/activities/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: activitiesUpdate
export def "activities-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account-id: string # nullable, e.g. 12345
  --activity-date: string # nullable, e.g. 2021-05-01
  --activity-datetime: string # nullable, e.g. 2021-05-01T12:00:00.000Z
  --all-day-event: oneof<nothing, bool> # e.g. false
  --archived: oneof<nothing, bool> # e.g. false
  --asset-id: string # nullable, e.g. 12345
  --attendees: list # item shape: {email_address?: string, first_name?: string, is_organizer?: bool, last_name?: string, middle_name?: string, name?: string, prefix?: string, status?: "accepted"|"tentative"|"declined", suffix?: string}
  --campaign-id: string # nullable, e.g. 12345
  --case-id: string # nullable, e.g. 12345
  --child: oneof<nothing, bool> # e.g. false
  --company-id: string # nullable, e.g. 12345
  --contact-id: string # nullable, e.g. 12345
  --contract-id: string # nullable, e.g. 12345
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --custom-object-id: string # nullable, e.g. 12345
  --deleted: oneof<nothing, bool> # e.g. false
  --description: string # nullable, e.g. More info about the meeting
  --done: oneof<nothing, bool> # Whether the Activity is done or not (e.g. false)
  --duration-seconds: int # nullable, e.g. 1800
  --end-date: string # nullable, e.g. 2021-05-01
  --end-datetime: string # nullable, e.g. 2021-05-01T12:30:00.000Z
  --event-sub-type: string # nullable, e.g. debrief
  --group-event: oneof<nothing, bool> # e.g. true
  --group-event-type: string # nullable, e.g. Proposed
  --lead-id: string # nullable, e.g. 12345
  --location: string # nullable, e.g. Space
  --location-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --note: string # nullable, e.g. An internal note about the meeting
  --opportunity-id: string # nullable, e.g. 12345
  --owner-id: string # nullable, e.g. 12345
  --private: oneof<nothing, bool> # e.g. true
  --product-id: string # nullable, e.g. 12345
  --recurrent: oneof<nothing, bool> # e.g. false
  --reminder-datetime: string # nullable, e.g. 2021-05-01T17:00:00.000Z
  --reminder-set: oneof<nothing, bool> # nullable, e.g. false
  --show-as: string@show-as-completer # e.g. busy
  --solution-id: string # nullable, e.g. 12345
  --start-datetime: string # nullable, e.g. 2021-05-01T12:00:00.000Z
  --title: string # nullable, e.g. Meeting
  type: string@type-completer # e.g. meeting
  --user-id: string # nullable, e.g. 12345
  --video-conference-id: string # e.g. zoom:88120759396
  --video-conference-url: string # e.g. https://us02web.zoom.us/j/88120759396
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/activities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: activity_date, var: activity_date}, {name: activity_datetime, var: activity_datetime}, {name: all_day_event, var: all_day_event}, {name: archived, var: archived}, {name: asset_id, var: asset_id}, {name: attendees, var: attendees}, {name: campaign_id, var: campaign_id}, {name: case_id, var: case_id}, {name: child, var: child}, {name: company_id, var: company_id}, {name: contact_id, var: contact_id}, {name: contract_id, var: contract_id}, {name: custom_fields, var: custom_fields}, {name: custom_object_id, var: custom_object_id}, {name: deleted, var: deleted}, {name: description, var: description}, {name: done, var: done}, {name: duration_seconds, var: duration_seconds}, {name: end_date, var: end_date}, {name: end_datetime, var: end_datetime}, {name: event_sub_type, var: event_sub_type}, {name: group_event, var: group_event}, {name: group_event_type, var: group_event_type}, {name: lead_id, var: lead_id}, {name: location, var: location}, {name: location_address, var: location_address}, {name: note, var: note}, {name: opportunity_id, var: opportunity_id}, {name: owner_id, var: owner_id}, {name: private, var: private}, {name: product_id, var: product_id}, {name: recurrent, var: recurrent}, {name: reminder_datetime, var: reminder_datetime}, {name: reminder_set, var: reminder_set}, {name: show_as, var: show_as}, {name: solution_id, var: solution_id}, {name: start_datetime, var: start_datetime}, {name: title, var: title}, {name: type, var: type}, {name: user_id, var: user_id}, {name: video_conference_id, var: video_conference_id}, {name: video_conference_url, var: video_conference_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, account_id: $account_id, activity_date: $activity_date, activity_datetime: $activity_datetime, all_day_event: $all_day_event, archived: $archived, asset_id: $asset_id, attendees: $attendees, campaign_id: $campaign_id, case_id: $case_id, child: $child, company_id: $company_id, contact_id: $contact_id, contract_id: $contract_id, custom_fields: $custom_fields, custom_object_id: $custom_object_id, deleted: $deleted, description: $description, done: $done, duration_seconds: $duration_seconds, end_date: $end_date, end_datetime: $end_datetime, event_sub_type: $event_sub_type, group_event: $group_event, group_event_type: $group_event_type, lead_id: $lead_id, location: $location, location_address: $location_address, note: $note, opportunity_id: $opportunity_id, owner_id: $owner_id, private: $private, product_id: $product_id, recurrent: $recurrent, reminder_datetime: $reminder_datetime, reminder_set: $reminder_set, show_as: $show_as, solution_id: $solution_id, start_datetime: $start_datetime, title: $title, type: $type, user_id: $user_id, video_conference_id: $video_conference_id, video_conference_url: $video_conference_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List companies
#
# GET /crm/companies
# Returns: record<data: table<abn_branch: string, abn_or_tfn: string, acn: string, addresses: list, annual_revenue: string, bank_accounts: list, birthday: string, created_at: string, created_by: string, currency: string, custom_fields: list, deleted: bool, description: string, emails: list, fax: string, first_name: string, id: string, image: string, industry: string, interaction_count: int, last_activity_at: string, last_name: string, name: string, number_of_employees: string, owner_id: string, ownership: string, parent_id: string, payee_number: string, phone_numbers: list, read_only: bool, row_type: record, sales_tax_number: string, salutation: string, social_links: list, status: string, tags: list, updated_at: string, updated_by: string, vat_number: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companiesAll
export def "companies-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {name: SpaceX})
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/companies"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create company
#
# POST /crm/companies
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companiesAdd
export def "companies-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --abn-branch: string # An ABN Branch (also known as a GST Branch) is used if part of your business needs to account for GST separately from its parent entity. (nullable, e.g. 123)
  --abn-or-tfn: string # An ABN is necessary for operating a business, while a TFN (Tax File Number) is required for any person working in Australia. (nullable, e.g. 46 115 614 695)
  --acn: string # The Australian Company Number (ACN) is a nine digit number with the last digit being a check digit calculated using a modified modulus 10 calculation. ASIC has adopted a convention of always printing and displaying the ACN in the format XXX XXX XXX; three blocks of three characters, each block separated by a blank. (nullable, e.g. XXX XXX XXX)
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --annual-revenue: string # Annual revenue (nullable, e.g. +$35m)
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --birthday: string # The date of birth of the person. (nullable, format: date, e.g. 2000-08-12)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # nullable, e.g. Space Exploration Technologies Corp. is an American aerospace manufacturer, space transportation services and communications company headquartered in Hawthorne, California.
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --image: string # nullable, e.g. https://www.spacex.com/static/images/share.jpg
  --industry: string # Industry (nullable, e.g. Apparel)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  name: string # e.g. SpaceX
  --number-of-employees: string # Number of employees (nullable, e.g. 500-1000)
  --owner-id: string # e.g. 12345
  --ownership: string # Ownership (nullable, e.g. Public)
  --payee-number: string # nullable, e.g. 78932EN
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --read-only: oneof<nothing, bool> # nullable, e.g. false
  --row-type: record # shape: {id?: string, name?: string}
  --sales-tax-number: string # nullable, e.g. 12456EN
  --salutation: string # A formal salutation for the person. For example, 'Mr', 'Mrs' (nullable, e.g. Mr)
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. Open
  --tags: list<string> # e.g. [New]
  --vat-number: string # VAT number (nullable, e.g. BE0689615164)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/companies"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abn_branch, var: abn_branch}, {name: abn_or_tfn, var: abn_or_tfn}, {name: acn, var: acn}, {name: addresses, var: addresses}, {name: annual_revenue, var: annual_revenue}, {name: bank_accounts, var: bank_accounts}, {name: birthday, var: birthday}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: image, var: image}, {name: industry, var: industry}, {name: last_name, var: last_name}, {name: name, var: name}, {name: number_of_employees, var: number_of_employees}, {name: owner_id, var: owner_id}, {name: ownership, var: ownership}, {name: payee_number, var: payee_number}, {name: phone_numbers, var: phone_numbers}, {name: read_only, var: read_only}, {name: row_type, var: row_type}, {name: sales_tax_number, var: sales_tax_number}, {name: salutation, var: salutation}, {name: social_links, var: social_links}, {name: status, var: status}, {name: tags, var: tags}, {name: vat_number, var: vat_number}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, abn_branch: $abn_branch, abn_or_tfn: $abn_or_tfn, acn: $acn, addresses: $addresses, annual_revenue: $annual_revenue, bank_accounts: $bank_accounts, birthday: $birthday, currency: $currency, custom_fields: $custom_fields, description: $description, emails: $emails, fax: $fax, first_name: $first_name, image: $image, industry: $industry, last_name: $last_name, name: $name, number_of_employees: $number_of_employees, owner_id: $owner_id, ownership: $ownership, payee_number: $payee_number, phone_numbers: $phone_numbers, read_only: $read_only, row_type: $row_type, sales_tax_number: $sales_tax_number, salutation: $salutation, social_links: $social_links, status: $status, tags: $tags, vat_number: $vat_number, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete company
#
# DELETE /crm/companies/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companiesDelete
export def "companies-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/companies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get company
#
# GET /crm/companies/{id}
# Returns: record<data: record<abn_branch: string, abn_or_tfn: string, acn: string, addresses: list<record>, annual_revenue: string, bank_accounts: list<record>, birthday: string, created_at: string, created_by: string, currency: string, custom_fields: list<record>, deleted: bool, description: string, emails: list<record>, fax: string, first_name: string, id: string, image: string, industry: string, interaction_count: int, last_activity_at: string, last_name: string, name: string, number_of_employees: string, owner_id: string, ownership: string, parent_id: string, payee_number: string, phone_numbers: list<record>, read_only: bool, row_type: record<id: string, name: string>, sales_tax_number: string, salutation: string, social_links: list<record>, status: string, tags: list<string>, updated_at: string, updated_by: string, vat_number: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companiesOne
export def "companies-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/companies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update company
#
# PATCH /crm/companies/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: companiesUpdate
export def "companies-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --abn-branch: string # An ABN Branch (also known as a GST Branch) is used if part of your business needs to account for GST separately from its parent entity. (nullable, e.g. 123)
  --abn-or-tfn: string # An ABN is necessary for operating a business, while a TFN (Tax File Number) is required for any person working in Australia. (nullable, e.g. 46 115 614 695)
  --acn: string # The Australian Company Number (ACN) is a nine digit number with the last digit being a check digit calculated using a modified modulus 10 calculation. ASIC has adopted a convention of always printing and displaying the ACN in the format XXX XXX XXX; three blocks of three characters, each block separated by a blank. (nullable, e.g. XXX XXX XXX)
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --annual-revenue: string # Annual revenue (nullable, e.g. +$35m)
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, ... (2 more fields)}
  --birthday: string # The date of birth of the person. (nullable, format: date, e.g. 2000-08-12)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # nullable, e.g. Space Exploration Technologies Corp. is an American aerospace manufacturer, space transportation services and communications company headquartered in Hawthorne, California.
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --image: string # nullable, e.g. https://www.spacex.com/static/images/share.jpg
  --industry: string # Industry (nullable, e.g. Apparel)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  name: string # e.g. SpaceX
  --number-of-employees: string # Number of employees (nullable, e.g. 500-1000)
  --owner-id: string # e.g. 12345
  --ownership: string # Ownership (nullable, e.g. Public)
  --payee-number: string # nullable, e.g. 78932EN
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --read-only: oneof<nothing, bool> # nullable, e.g. false
  --row-type: record # shape: {id?: string, name?: string}
  --sales-tax-number: string # nullable, e.g. 12456EN
  --salutation: string # A formal salutation for the person. For example, 'Mr', 'Mrs' (nullable, e.g. Mr)
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. Open
  --tags: list<string> # e.g. [New]
  --vat-number: string # VAT number (nullable, e.g. BE0689615164)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/companies/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: abn_branch, var: abn_branch}, {name: abn_or_tfn, var: abn_or_tfn}, {name: acn, var: acn}, {name: addresses, var: addresses}, {name: annual_revenue, var: annual_revenue}, {name: bank_accounts, var: bank_accounts}, {name: birthday, var: birthday}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: image, var: image}, {name: industry, var: industry}, {name: last_name, var: last_name}, {name: name, var: name}, {name: number_of_employees, var: number_of_employees}, {name: owner_id, var: owner_id}, {name: ownership, var: ownership}, {name: payee_number, var: payee_number}, {name: phone_numbers, var: phone_numbers}, {name: read_only, var: read_only}, {name: row_type, var: row_type}, {name: sales_tax_number, var: sales_tax_number}, {name: salutation, var: salutation}, {name: social_links, var: social_links}, {name: status, var: status}, {name: tags, var: tags}, {name: vat_number, var: vat_number}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, abn_branch: $abn_branch, abn_or_tfn: $abn_or_tfn, acn: $acn, addresses: $addresses, annual_revenue: $annual_revenue, bank_accounts: $bank_accounts, birthday: $birthday, currency: $currency, custom_fields: $custom_fields, description: $description, emails: $emails, fax: $fax, first_name: $first_name, image: $image, industry: $industry, last_name: $last_name, name: $name, number_of_employees: $number_of_employees, owner_id: $owner_id, ownership: $ownership, payee_number: $payee_number, phone_numbers: $phone_numbers, read_only: $read_only, row_type: $row_type, sales_tax_number: $sales_tax_number, salutation: $salutation, social_links: $social_links, status: $status, tags: $tags, vat_number: $vat_number, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List contacts
#
# GET /crm/contacts
# Returns: record<data: table<active: bool, addresses: list, birthday: string, company_id: string, company_name: string, created_at: string, current_balance: float, custom_fields: list, department: string, description: string, email_domain: string, emails: list, fax: string, first_call_at: string, first_email_at: string, first_name: string, gender: string, id: string, image: string, language: string, last_activity_at: string, last_name: string, lead_id: string, lead_source: string, middle_name: string, name: string, owner_id: string, phone_numbers: list, photo_url: string, prefix: string, social_links: list, status: string, suffix: string, tags: list, title: string, type: string, updated_at: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: contactsAll
export def "contacts-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {company_id: 12345, email: elon@tesla.com, first_name: Elon, last_name: Musk})
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/contacts"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create contact
#
# POST /crm/contacts
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: contactsAdd
@deprecated --flag image
export def "contacts-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --birthday: string # nullable, e.g. 2000-08-12
  --company-id: string # nullable, e.g. 23456
  --company-name: string # nullable, e.g. 23456
  --current-balance: float # nullable, e.g. 10.5
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --department: string # nullable, e.g. Engineering
  --description: string # nullable, e.g. Internal champion
  --email-domain: string # nullable, e.g. gmail.com
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # nullable, e.g. Elon
  --gender: string@gender-completer # nullable, e.g. female
  --image: string # DEPRECATED, nullable, e.g. https://unavatar.io/elon-musk
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # nullable, e.g. Musk
  --lead-id: string # nullable, e.g. 34567
  --lead-source: string # nullable, e.g. Cold Call
  --middle-name: string # nullable, e.g. D.
  name: string # e.g. Elon Musk
  --owner-id: string # nullable, e.g. 54321
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --photo-url: string # The URL of the photo of a person. (nullable, e.g. https://unavatar.io/elon-musk)
  --prefix: string # nullable, e.g. Mr.
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. open
  --suffix: string # nullable, e.g. PhD
  --tags: list<string> # e.g. [New]
  --title: string # nullable, e.g. CEO
  --type: string@type-completer-1 # nullable, e.g. personal
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/contacts"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: addresses, var: addresses}, {name: birthday, var: birthday}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: current_balance, var: current_balance}, {name: custom_fields, var: custom_fields}, {name: department, var: department}, {name: description, var: description}, {name: email_domain, var: email_domain}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: gender, var: gender}, {name: image, var: image}, {name: language, var: language}, {name: last_name, var: last_name}, {name: lead_id, var: lead_id}, {name: lead_source, var: lead_source}, {name: middle_name, var: middle_name}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone_numbers, var: phone_numbers}, {name: photo_url, var: photo_url}, {name: prefix, var: prefix}, {name: social_links, var: social_links}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tags, var: tags}, {name: title, var: title}, {name: type, var: type}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, addresses: $addresses, birthday: $birthday, company_id: $company_id, company_name: $company_name, current_balance: $current_balance, custom_fields: $custom_fields, department: $department, description: $description, email_domain: $email_domain, emails: $emails, fax: $fax, first_name: $first_name, gender: $gender, image: $image, language: $language, last_name: $last_name, lead_id: $lead_id, lead_source: $lead_source, middle_name: $middle_name, name: $name, owner_id: $owner_id, phone_numbers: $phone_numbers, photo_url: $photo_url, prefix: $prefix, social_links: $social_links, status: $status, suffix: $suffix, tags: $tags, title: $title, type: $type, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete contact
#
# DELETE /crm/contacts/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: contactsDelete
export def "contacts-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get contact
#
# GET /crm/contacts/{id}
# Returns: record<data: record<active: bool, addresses: list<record>, birthday: string, company_id: string, company_name: string, created_at: string, current_balance: float, custom_fields: list<record>, department: string, description: string, email_domain: string, emails: list<record>, fax: string, first_call_at: string, first_email_at: string, first_name: string, gender: string, id: string, image: string, language: string, last_activity_at: string, last_name: string, lead_id: string, lead_source: string, middle_name: string, name: string, owner_id: string, phone_numbers: list<record>, photo_url: string, prefix: string, social_links: list<record>, status: string, suffix: string, tags: list<string>, title: string, type: string, updated_at: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: contactsOne
export def "contacts-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update contact
#
# PATCH /crm/contacts/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: contactsUpdate
@deprecated --flag image
export def "contacts-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --birthday: string # nullable, e.g. 2000-08-12
  --company-id: string # nullable, e.g. 23456
  --company-name: string # nullable, e.g. 23456
  --current-balance: float # nullable, e.g. 10.5
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --department: string # nullable, e.g. Engineering
  --description: string # nullable, e.g. Internal champion
  --email-domain: string # nullable, e.g. gmail.com
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # nullable, e.g. Elon
  --gender: string@gender-completer # nullable, e.g. female
  --image: string # DEPRECATED, nullable, e.g. https://unavatar.io/elon-musk
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # nullable, e.g. Musk
  --lead-id: string # nullable, e.g. 34567
  --lead-source: string # nullable, e.g. Cold Call
  --middle-name: string # nullable, e.g. D.
  name: string # e.g. Elon Musk
  --owner-id: string # nullable, e.g. 54321
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --photo-url: string # The URL of the photo of a person. (nullable, e.g. https://unavatar.io/elon-musk)
  --prefix: string # nullable, e.g. Mr.
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. open
  --suffix: string # nullable, e.g. PhD
  --tags: list<string> # e.g. [New]
  --title: string # nullable, e.g. CEO
  --type: string@type-completer-1 # nullable, e.g. personal
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/contacts/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: addresses, var: addresses}, {name: birthday, var: birthday}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: current_balance, var: current_balance}, {name: custom_fields, var: custom_fields}, {name: department, var: department}, {name: description, var: description}, {name: email_domain, var: email_domain}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: gender, var: gender}, {name: image, var: image}, {name: language, var: language}, {name: last_name, var: last_name}, {name: lead_id, var: lead_id}, {name: lead_source, var: lead_source}, {name: middle_name, var: middle_name}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone_numbers, var: phone_numbers}, {name: photo_url, var: photo_url}, {name: prefix, var: prefix}, {name: social_links, var: social_links}, {name: status, var: status}, {name: suffix, var: suffix}, {name: tags, var: tags}, {name: title, var: title}, {name: type, var: type}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, addresses: $addresses, birthday: $birthday, company_id: $company_id, company_name: $company_name, current_balance: $current_balance, custom_fields: $custom_fields, department: $department, description: $description, email_domain: $email_domain, emails: $emails, fax: $fax, first_name: $first_name, gender: $gender, image: $image, language: $language, last_name: $last_name, lead_id: $lead_id, lead_source: $lead_source, middle_name: $middle_name, name: $name, owner_id: $owner_id, phone_numbers: $phone_numbers, photo_url: $photo_url, prefix: $prefix, social_links: $social_links, status: $status, suffix: $suffix, tags: $tags, title: $title, type: $type, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List leads
#
# GET /crm/leads
# Returns: record<data: table<addresses: list, company_id: string, company_name: string, contact_id: string, created_at: string, currency: string, custom_fields: list, description: string, emails: list, fax: string, first_name: string, id: string, language: string, last_name: string, lead_source: string, monetary_amount: float, name: string, owner_id: string, phone_numbers: list, prefix: string, social_links: list, status: string, tags: list, title: string, updated_at: string, websites: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: leadsAll
export def "leads-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {email: elon@tesla.com, first_name: Elon, last_name: Musk})
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/leads"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create lead
#
# POST /crm/leads
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: leadsAdd
export def "leads-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-id: string # nullable, e.g. 2
  --company-name: string # nullable, e.g. Spacex
  --contact-id: string # nullable, e.g. 2
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # nullable, e.g. A thinker
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # nullable, e.g. Elon
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # nullable, e.g. Musk
  --lead-source: string # nullable, e.g. Cold Call
  --monetary-amount: float # nullable, e.g. 75000
  name: string # e.g. Elon Musk
  --owner-id: string # e.g. 54321
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --prefix: string # nullable, e.g. Sir
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. New
  --tags: list<string> # e.g. [New]
  --title: string # nullable, e.g. CEO
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/leads"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: contact_id, var: contact_id}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: language, var: language}, {name: last_name, var: last_name}, {name: lead_source, var: lead_source}, {name: monetary_amount, var: monetary_amount}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone_numbers, var: phone_numbers}, {name: prefix, var: prefix}, {name: social_links, var: social_links}, {name: status, var: status}, {name: tags, var: tags}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, addresses: $addresses, company_id: $company_id, company_name: $company_name, contact_id: $contact_id, currency: $currency, custom_fields: $custom_fields, description: $description, emails: $emails, fax: $fax, first_name: $first_name, language: $language, last_name: $last_name, lead_source: $lead_source, monetary_amount: $monetary_amount, name: $name, owner_id: $owner_id, phone_numbers: $phone_numbers, prefix: $prefix, social_links: $social_links, status: $status, tags: $tags, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete lead
#
# DELETE /crm/leads/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: leadsDelete
export def "leads-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/leads/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get lead
#
# GET /crm/leads/{id}
# Returns: record<data: record<addresses: list<record>, company_id: string, company_name: string, contact_id: string, created_at: string, currency: string, custom_fields: list<record>, description: string, emails: list<record>, fax: string, first_name: string, id: string, language: string, last_name: string, lead_source: string, monetary_amount: float, name: string, owner_id: string, phone_numbers: list<record>, prefix: string, social_links: list<record>, status: string, tags: list<string>, title: string, updated_at: string, websites: list<record>>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: leadsOne
export def "leads-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/leads/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update lead
#
# PATCH /crm/leads/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: leadsUpdate
export def "leads-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-id: string # nullable, e.g. 2
  --company-name: string # nullable, e.g. Spacex
  --contact-id: string # nullable, e.g. 2
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # nullable, e.g. A thinker
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --fax: string # nullable, e.g. +12129876543
  --first-name: string # nullable, e.g. Elon
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # nullable, e.g. Musk
  --lead-source: string # nullable, e.g. Cold Call
  --monetary-amount: float # nullable, e.g. 75000
  name: string # e.g. Elon Musk
  --owner-id: string # e.g. 54321
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --prefix: string # nullable, e.g. Sir
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --status: string # nullable, e.g. New
  --tags: list<string> # e.g. [New]
  --title: string # nullable, e.g. CEO
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/leads/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: contact_id, var: contact_id}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: emails, var: emails}, {name: fax, var: fax}, {name: first_name, var: first_name}, {name: language, var: language}, {name: last_name, var: last_name}, {name: lead_source, var: lead_source}, {name: monetary_amount, var: monetary_amount}, {name: name, var: name}, {name: owner_id, var: owner_id}, {name: phone_numbers, var: phone_numbers}, {name: prefix, var: prefix}, {name: social_links, var: social_links}, {name: status, var: status}, {name: tags, var: tags}, {name: title, var: title}, {name: websites, var: websites}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, addresses: $addresses, company_id: $company_id, company_name: $company_name, contact_id: $contact_id, currency: $currency, custom_fields: $custom_fields, description: $description, emails: $emails, fax: $fax, first_name: $first_name, language: $language, last_name: $last_name, lead_source: $lead_source, monetary_amount: $monetary_amount, name: $name, owner_id: $owner_id, phone_numbers: $phone_numbers, prefix: $prefix, social_links: $social_links, status: $status, tags: $tags, title: $title, websites: $websites
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List notes
#
# GET /crm/notes
# Returns: record<data: table<active: bool, company_id: string, contact_id: string, content: string, created_at: string, created_by: string, id: string, lead_id: string, opportunity_id: string, owner_id: string, title: string, updated_at: string, updated_by: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: notesAll
export def "notes-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/notes"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create note
#
# POST /crm/notes
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: notesAdd
export def "notes-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --company-id: string # nullable, e.g. 12345
  --contact-id: string # nullable, e.g. 12345
  --content: string # e.g. Office hours are 9AM-6PM
  --lead-id: string # nullable, e.g. 12345
  --opportunity-id: string # nullable, e.g. 12345
  --owner-id: string # e.g. 12345
  --title: string # e.g. Meeting Notes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/notes"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: company_id, var: company_id}, {name: contact_id, var: contact_id}, {name: content, var: content}, {name: lead_id, var: lead_id}, {name: opportunity_id, var: opportunity_id}, {name: owner_id, var: owner_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, company_id: $company_id, contact_id: $contact_id, content: $content, lead_id: $lead_id, opportunity_id: $opportunity_id, owner_id: $owner_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete note
#
# DELETE /crm/notes/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: notesDelete
export def "notes-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get note
#
# GET /crm/notes/{id}
# Returns: record<data: record<active: bool, company_id: string, contact_id: string, content: string, created_at: string, created_by: string, id: string, lead_id: string, opportunity_id: string, owner_id: string, title: string, updated_at: string, updated_by: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: notesOne
export def "notes-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update note
#
# PATCH /crm/notes/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: notesUpdate
export def "notes-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # nullable, e.g. true
  --company-id: string # nullable, e.g. 12345
  --contact-id: string # nullable, e.g. 12345
  --content: string # e.g. Office hours are 9AM-6PM
  --lead-id: string # nullable, e.g. 12345
  --opportunity-id: string # nullable, e.g. 12345
  --owner-id: string # e.g. 12345
  --title: string # e.g. Meeting Notes
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/notes/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: company_id, var: company_id}, {name: contact_id, var: contact_id}, {name: content, var: content}, {name: lead_id, var: lead_id}, {name: opportunity_id, var: opportunity_id}, {name: owner_id, var: owner_id}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, company_id: $company_id, contact_id: $contact_id, content: $content, lead_id: $lead_id, opportunity_id: $opportunity_id, owner_id: $owner_id, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List opportunities
#
# GET /crm/opportunities
# Returns: record<data: table<close_date: string, company_id: string, company_name: string, contact_id: string, contact_ids: list, created_at: string, created_by: string, currency: string, custom_fields: list, date_last_contacted: string, date_lead_created: string, date_stage_changed: string, deleted: bool, description: string, expected_revenue: float, id: string, interaction_count: float, last_activity_at: string, lead_id: string, lead_source: string, loss_reason: string, loss_reason_id: string, monetary_amount: float, owner_id: string, pipeline_id: string, pipeline_stage_id: string, primary_contact_id: string, priority: string, source_id: string, stage_last_changed_at: string, status: string, status_id: string, tags: list, title: string, type: string, updated_at: string, updated_by: string, win_probability: float, won_reason: string, won_reason_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: opportunitiesAll
export def "opportunities-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {monetary_amount: 75000, status: Completed})
  --sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/opportunities"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: filter, var: filter, style: deepObject}, {name: sort, var: sort, style: deepObject}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, filter: $filter, sort: $sort, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create opportunity
#
# POST /crm/opportunities
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: opportunitiesAdd
export def "opportunities-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --close-date: string # The actual closing date for the opportunity. If close_date is null, the opportunity is not closed yet. (nullable, format: date, e.g. 2020-10-30)
  --company-id: string # The unique identifier of the company associated with the opportunity. (nullable, e.g. 12345)
  --company-name: string # The name of the company associated with the opportunity. (nullable, e.g. Copper)
  --contact-id: string # The unique identifier of the contact associated with the opportunity. (nullable, e.g. 12345)
  --contact-ids: list<string> # An array of unique identifiers of all contacts associated with the opportunity.
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # A description of the opportunity. (nullable, e.g. Opportunities are created for People and Companies that are interested in buying your products or services. Create Opportunities for People and Companies to move them through one of your Pipelines.)
  --lead-id: string # The unique identifier of the lead associated with the opportunity. (nullable, e.g. 12345)
  --lead-source: string # The source of the lead associated with the opportunity. (nullable, e.g. Website)
  --loss-reason: string # The reason why the opportunity was lost. (nullable, e.g. No budget)
  --loss-reason-id: string # The unique identifier of the reason why the opportunity was lost. (nullable, e.g. 12345)
  --monetary-amount: float # The monetary value associated with the opportunity (nullable, e.g. 75000)
  --owner-id: string # The unique identifier of the user who owns the opportunity. (nullable, e.g. 12345)
  --pipeline-id: string # The unique identifier of the pipeline associated with the opportunity (nullable, e.g. 12345)
  --pipeline-stage-id: string # The unique identifier of the stage in the pipeline associated with the opportunity. (nullable, e.g. 12345)
  --primary-contact-id: string # The unique identifier of the primary contact associated with the opportunity. (nullable, e.g. 12345)
  --priority: string # The priority level of the opportunity. (nullable, e.g. None)
  --source-id: string # The unique identifier of the source of the opportunity. (nullable, e.g. 12345)
  --stage-last-changed-at: string # The date and time when the stage of the opportunity was last changed. (nullable, format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --status: string # The current status of the opportunity. (nullable, e.g. Open)
  --status-id: string # The unique identifier of the current status of the opportunity. (nullable, e.g. 12345)
  --tags: list<string> # e.g. [New]
  title: string # The title or name of the opportunity. (e.g. New Rocket)
  --type: string # The type of the opportunity (nullable, e.g. Existing Customer - Upgrade)
  --win-probability: float # The probability of winning the opportunity, expressed as a percentage. (nullable, e.g. 40)
  --won-reason: string # The reason why the opportunity was won. (nullable, e.g. Best pitch)
  --won-reason-id: string # The unique identifier of the reason why the opportunity was won. (nullable, e.g. 12345)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/opportunities"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: close_date, var: close_date}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: contact_id, var: contact_id}, {name: contact_ids, var: contact_ids}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: lead_id, var: lead_id}, {name: lead_source, var: lead_source}, {name: loss_reason, var: loss_reason}, {name: loss_reason_id, var: loss_reason_id}, {name: monetary_amount, var: monetary_amount}, {name: owner_id, var: owner_id}, {name: pipeline_id, var: pipeline_id}, {name: pipeline_stage_id, var: pipeline_stage_id}, {name: primary_contact_id, var: primary_contact_id}, {name: priority, var: priority}, {name: source_id, var: source_id}, {name: stage_last_changed_at, var: stage_last_changed_at}, {name: status, var: status}, {name: status_id, var: status_id}, {name: tags, var: tags}, {name: title, var: title}, {name: type, var: type}, {name: win_probability, var: win_probability}, {name: won_reason, var: won_reason}, {name: won_reason_id, var: won_reason_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, close_date: $close_date, company_id: $company_id, company_name: $company_name, contact_id: $contact_id, contact_ids: $contact_ids, currency: $currency, custom_fields: $custom_fields, description: $description, lead_id: $lead_id, lead_source: $lead_source, loss_reason: $loss_reason, loss_reason_id: $loss_reason_id, monetary_amount: $monetary_amount, owner_id: $owner_id, pipeline_id: $pipeline_id, pipeline_stage_id: $pipeline_stage_id, primary_contact_id: $primary_contact_id, priority: $priority, source_id: $source_id, stage_last_changed_at: $stage_last_changed_at, status: $status, status_id: $status_id, tags: $tags, title: $title, type: $type, win_probability: $win_probability, won_reason: $won_reason, won_reason_id: $won_reason_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete opportunity
#
# DELETE /crm/opportunities/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: opportunitiesDelete
export def "opportunities-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/opportunities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get opportunity
#
# GET /crm/opportunities/{id}
# Returns: record<data: record<close_date: string, company_id: string, company_name: string, contact_id: string, contact_ids: list<string>, created_at: string, created_by: string, currency: string, custom_fields: list<record>, date_last_contacted: string, date_lead_created: string, date_stage_changed: string, deleted: bool, description: string, expected_revenue: float, id: string, interaction_count: float, last_activity_at: string, lead_id: string, lead_source: string, loss_reason: string, loss_reason_id: string, monetary_amount: float, owner_id: string, pipeline_id: string, pipeline_stage_id: string, primary_contact_id: string, priority: string, source_id: string, stage_last_changed_at: string, status: string, status_id: string, tags: list<string>, title: string, type: string, updated_at: string, updated_by: string, win_probability: float, won_reason: string, won_reason_id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: opportunitiesOne
export def "opportunities-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/opportunities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update opportunity
#
# PATCH /crm/opportunities/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: opportunitiesUpdate
export def "opportunities-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --close-date: string # The actual closing date for the opportunity. If close_date is null, the opportunity is not closed yet. (nullable, format: date, e.g. 2020-10-30)
  --company-id: string # The unique identifier of the company associated with the opportunity. (nullable, e.g. 12345)
  --company-name: string # The name of the company associated with the opportunity. (nullable, e.g. Copper)
  --contact-id: string # The unique identifier of the contact associated with the opportunity. (nullable, e.g. 12345)
  --contact-ids: list<string> # An array of unique identifiers of all contacts associated with the opportunity.
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --description: string # A description of the opportunity. (nullable, e.g. Opportunities are created for People and Companies that are interested in buying your products or services. Create Opportunities for People and Companies to move them through one of your Pipelines.)
  --lead-id: string # The unique identifier of the lead associated with the opportunity. (nullable, e.g. 12345)
  --lead-source: string # The source of the lead associated with the opportunity. (nullable, e.g. Website)
  --loss-reason: string # The reason why the opportunity was lost. (nullable, e.g. No budget)
  --loss-reason-id: string # The unique identifier of the reason why the opportunity was lost. (nullable, e.g. 12345)
  --monetary-amount: float # The monetary value associated with the opportunity (nullable, e.g. 75000)
  --owner-id: string # The unique identifier of the user who owns the opportunity. (nullable, e.g. 12345)
  --pipeline-id: string # The unique identifier of the pipeline associated with the opportunity (nullable, e.g. 12345)
  --pipeline-stage-id: string # The unique identifier of the stage in the pipeline associated with the opportunity. (nullable, e.g. 12345)
  --primary-contact-id: string # The unique identifier of the primary contact associated with the opportunity. (nullable, e.g. 12345)
  --priority: string # The priority level of the opportunity. (nullable, e.g. None)
  --source-id: string # The unique identifier of the source of the opportunity. (nullable, e.g. 12345)
  --stage-last-changed-at: string # The date and time when the stage of the opportunity was last changed. (nullable, format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --status: string # The current status of the opportunity. (nullable, e.g. Open)
  --status-id: string # The unique identifier of the current status of the opportunity. (nullable, e.g. 12345)
  --tags: list<string> # e.g. [New]
  title: string # The title or name of the opportunity. (e.g. New Rocket)
  --type: string # The type of the opportunity (nullable, e.g. Existing Customer - Upgrade)
  --win-probability: float # The probability of winning the opportunity, expressed as a percentage. (nullable, e.g. 40)
  --won-reason: string # The reason why the opportunity was won. (nullable, e.g. Best pitch)
  --won-reason-id: string # The unique identifier of the reason why the opportunity was won. (nullable, e.g. 12345)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/opportunities/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: close_date, var: close_date}, {name: company_id, var: company_id}, {name: company_name, var: company_name}, {name: contact_id, var: contact_id}, {name: contact_ids, var: contact_ids}, {name: currency, var: currency}, {name: custom_fields, var: custom_fields}, {name: description, var: description}, {name: lead_id, var: lead_id}, {name: lead_source, var: lead_source}, {name: loss_reason, var: loss_reason}, {name: loss_reason_id, var: loss_reason_id}, {name: monetary_amount, var: monetary_amount}, {name: owner_id, var: owner_id}, {name: pipeline_id, var: pipeline_id}, {name: pipeline_stage_id, var: pipeline_stage_id}, {name: primary_contact_id, var: primary_contact_id}, {name: priority, var: priority}, {name: source_id, var: source_id}, {name: stage_last_changed_at, var: stage_last_changed_at}, {name: status, var: status}, {name: status_id, var: status_id}, {name: tags, var: tags}, {name: title, var: title}, {name: type, var: type}, {name: win_probability, var: win_probability}, {name: won_reason, var: won_reason}, {name: won_reason_id, var: won_reason_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, close_date: $close_date, company_id: $company_id, company_name: $company_name, contact_id: $contact_id, contact_ids: $contact_ids, currency: $currency, custom_fields: $custom_fields, description: $description, lead_id: $lead_id, lead_source: $lead_source, loss_reason: $loss_reason, loss_reason_id: $loss_reason_id, monetary_amount: $monetary_amount, owner_id: $owner_id, pipeline_id: $pipeline_id, pipeline_stage_id: $pipeline_stage_id, primary_contact_id: $primary_contact_id, priority: $priority, source_id: $source_id, stage_last_changed_at: $stage_last_changed_at, status: $status, status_id: $status_id, tags: $tags, title: $title, type: $type, win_probability: $win_probability, won_reason: $won_reason, won_reason_id: $won_reason_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List pipelines
#
# GET /crm/pipelines
# Returns: record<data: table<active: bool, archived: bool, created_at: string, currency: string, display_order: int, id: string, name: string, stages: list, updated_at: string, win_probability_enabled: bool>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: pipelinesAll
export def "pipelines-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/pipelines"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create pipeline
#
# POST /crm/pipelines
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: pipelinesAdd
export def "pipelines-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # e.g. false
  --archived: oneof<nothing, bool> # e.g. false
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-order: int # e.g. 1
  --id: string # e.g. default
  name: string # e.g. Sales Pipeline
  --stages: list # item shape: {display_order?: int, name?: string, value?: string, win_probability?: int}
  --win-probability-enabled: oneof<nothing, bool> # e.g. true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/pipelines"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: archived, var: archived}, {name: currency, var: currency}, {name: display_order, var: display_order}, {name: id, var: id}, {name: name, var: name}, {name: stages, var: stages}, {name: win_probability_enabled, var: win_probability_enabled}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, archived: $archived, currency: $currency, display_order: $display_order, id: $id, name: $name, stages: $stages, win_probability_enabled: $win_probability_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pipeline
#
# DELETE /crm/pipelines/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: pipelinesDelete
export def "pipelines-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/pipelines/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pipeline
#
# GET /crm/pipelines/{id}
# Returns: record<data: record<active: bool, archived: bool, created_at: string, currency: string, display_order: int, id: string, name: string, stages: list<record>, updated_at: string, win_probability_enabled: bool>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: pipelinesOne
export def "pipelines-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/pipelines/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update pipeline
#
# PATCH /crm/pipelines/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: pipelinesUpdate
export def "pipelines-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: oneof<nothing, bool> # e.g. false
  --archived: oneof<nothing, bool> # e.g. false
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-order: int # e.g. 1
  --body-id: string # e.g. default (spec name: id)
  name: string # e.g. Sales Pipeline
  --stages: list # item shape: {display_order?: int, name?: string, value?: string, win_probability?: int}
  --win-probability-enabled: oneof<nothing, bool> # e.g. true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/pipelines/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: active, var: active}, {name: archived, var: archived}, {name: currency, var: currency}, {name: display_order, var: display_order}, {name: id, var: body_id}, {name: name, var: name}, {name: stages, var: stages}, {name: win_probability_enabled, var: win_probability_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, active: $active, archived: $archived, currency: $currency, display_order: $display_order, body_id: $body_id, name: $name, stages: $stages, win_probability_enabled: $win_probability_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List users
#
# GET /crm/users
# Returns: record<data: table<addresses: list, company_name: string, created_at: string, department: string, description: string, division: string, emails: list, employee_number: string, first_name: string, id: string, image: string, language: string, last_name: string, parent_id: string, password: string, phone_numbers: list, status: string, title: string, updated_at: string, username: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: usersAll
export def "users-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/users"
    query: [{name: raw, var: qp_raw}, {name: cursor, var: cursor}, {name: limit, var: limit}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    qp_raw: $qp_raw, cursor: $cursor, limit: $limit, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user
#
# POST /crm/users
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: usersAdd
@deprecated --flag department
export def "users-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --department: string # The department the person is currently in. [Deprecated](https://developers.apideck.com/changelog) in favor of the dedicated department_id and department_name field. (DEPRECATED, nullable, e.g. R&D)
  --description: string # A description of the object. (nullable, e.g. A description)
  --division: string # The division the person is currently in. Usually a collection of departments or teams or regions. (nullable, e.g. Europe)
  emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --employee-number: string # An Employee Number, Employee ID or Employee Code, is a unique number that has been assigned to each individual staff member within a company. (nullable, e.g. 123456-AB)
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --image: string # nullable, e.g. https://logo.clearbit.com/spacex.com?s=128
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --parent-id: string # nullable, e.g. 54321
  --password: string # e.g. supersecretpassword
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --status: string # nullable, e.g. active
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --username: string # nullable, e.g. masterofcoin
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/crm/users"
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: company_name, var: company_name}, {name: department, var: department}, {name: description, var: description}, {name: division, var: division}, {name: emails, var: emails}, {name: employee_number, var: employee_number}, {name: first_name, var: first_name}, {name: image, var: image}, {name: language, var: language}, {name: last_name, var: last_name}, {name: parent_id, var: parent_id}, {name: password, var: password}, {name: phone_numbers, var: phone_numbers}, {name: status, var: status}, {name: title, var: title}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, addresses: $addresses, company_name: $company_name, department: $department, description: $description, division: $division, emails: $emails, employee_number: $employee_number, first_name: $first_name, image: $image, language: $language, last_name: $last_name, parent_id: $parent_id, password: $password, phone_numbers: $phone_numbers, status: $status, title: $title, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /crm/users/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: usersDelete
export def "users-delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/crm/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user
#
# GET /crm/users/{id}
# Returns: record<data: record<addresses: list<record>, company_name: string, created_at: string, department: string, description: string, division: string, emails: list<record>, employee_number: string, first_name: string, id: string, image: string, language: string, last_name: string, parent_id: string, password: string, phone_numbers: list<record>, status: string, title: string, updated_at: string, username: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: usersOne
export def "users-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/crm/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}, {name: fields, var: fields}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, fields: $fields, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update user
#
# PATCH /crm/users/{id}
# Returns: record<data: record<id: string>, operation: string, resource: string, service: string, status: string, status_code: int>
# operationId: usersUpdate
@deprecated --flag department
export def "users-update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false) (spec name: raw)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --department: string # The department the person is currently in. [Deprecated](https://developers.apideck.com/changelog) in favor of the dedicated department_id and department_name field. (DEPRECATED, nullable, e.g. R&D)
  --description: string # A description of the object. (nullable, e.g. A description)
  --division: string # The division the person is currently in. Usually a collection of departments or teams or regions. (nullable, e.g. Europe)
  emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --employee-number: string # An Employee Number, Employee ID or Employee Code, is a unique number that has been assigned to each individual staff member within a company. (nullable, e.g. 123456-AB)
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --image: string # nullable, e.g. https://logo.clearbit.com/spacex.com?s=128
  --language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --parent-id: string # nullable, e.g. 54321
  --password: string # e.g. supersecretpassword
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --status: string # nullable, e.g. active
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --username: string # nullable, e.g. masterofcoin
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/crm/users/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: raw, var: qp_raw}]
    header: [{name: x-apideck-consumer-id, var: x_apideck_consumer_id, required: true}, {name: x-apideck-app-id, var: x_apideck_app_id, required: true}, {name: x-apideck-service-id, var: x_apideck_service_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: company_name, var: company_name}, {name: department, var: department}, {name: description, var: description}, {name: division, var: division}, {name: emails, var: emails}, {name: employee_number, var: employee_number}, {name: first_name, var: first_name}, {name: image, var: image}, {name: language, var: language}, {name: last_name, var: last_name}, {name: parent_id, var: parent_id}, {name: password, var: password}, {name: phone_numbers, var: phone_numbers}, {name: status, var: status}, {name: title, var: title}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, qp_raw: $qp_raw, x_apideck_consumer_id: $x_apideck_consumer_id, x_apideck_app_id: $x_apideck_app_id, x_apideck_service_id: $x_apideck_service_id, addresses: $addresses, company_name: $company_name, department: $department, description: $description, division: $division, emails: $emails, employee_number: $employee_number, first_name: $first_name, image: $image, language: $language, last_name: $last_name, parent_id: $parent_id, password: $password, phone_numbers: $phone_numbers, status: $status, title: $title, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
