# Auto-generated client for Files v3
# Source: https://api.apis.guru/v2/specs/hubapi.com/files/v3/openapi.json
# Auth: --token flag or $env.FILES_TOKEN

const CLIENT = {
  base_url: "https://api.hubapi.com"
  token_env_var: "FILES_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-hapikey, in: query, header_name: hapikey, prefix: ""}
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
    {name: private-app-legacy, in: header, header_name: private-app-legacy, prefix: ""}
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

def base-url-completer [] { ["https://api.hubapi.com"] }
def auth-scheme-completer [] { ["query-hapikey" "bearer" "private-app-legacy"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json"] }
def access-completer [] { ["HIDDEN_INDEXABLE" "HIDDEN_NOT_INDEXABLE" "HIDDEN_PRIVATE" "PRIVATE" "PUBLIC_INDEXABLE" "PUBLIC_NOT_INDEXABLE"] }
def duplicate-validation-scope-completer [] { ["ENTIRE_PORTAL" "EXACT_FOLDER"] }
def duplicate-validation-strategy-completer [] { ["NONE" "REJECT" "RETURN_EXISTING"] }
def size-completer [] { ["icon" "medium" "preview" "thumb"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    post-files-v3-files-upload: "record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>"
    post-files-v3-files-import-from-url-async-import-from-url: "record<id: string, links: record>"
    get-files-v3-files-import-from-url-async-tasks-status-check-import: "record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>, startedAt: string, status: string, taskId: string>"
    get-files-v3-files-search-do-search: "record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>>"
    get-files-v3-files-get-by-id: "record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>"
    patch-files-v3-files-update-properties: "record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>"
    put-files-v3-files-replace: "record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>"
    get-files-v3-files-signed-url-get-signed-url: "record<expiresAt: string, extension: string, height: int, name: string, size: int, type: string, url: string, width: int>"
    post-files-v3-folders-create: "record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>"
    get-files-v3-folders-search-do-search: "record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>>"
    post-files-v3-folders-update-async-update-properties: "record<id: string, links: record>"
    get-files-v3-folders-update-async-tasks-status-check-update-status: "record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>, startedAt: string, status: string, taskId: string>"
    get-files-v3-folders-get-by-id: "record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>"
    get-files-v3-folders-get-by-path: "record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-files-v3-files-upload" "post-files-v3-files-import-from-url-async-import-from-url" "get-files-v3-files-import-from-url-async-tasks-status-check-import" "get-files-v3-files-search-do-search" "delete-files-v3-files-archive" "get-files-v3-files-get-by-id" "patch-files-v3-files-update-properties" "put-files-v3-files-replace" "delete-files-v3-files-gdpr-delete-archive-gdpr" "get-files-v3-files-signed-url-get-signed-url" "post-files-v3-folders-create" "get-files-v3-folders-search-do-search" "post-files-v3-folders-update-async-update-properties" "get-files-v3-folders-update-async-tasks-status-check-update-status" "delete-files-v3-folders-archive" "get-files-v3-folders-get-by-id" "delete-files-v3-folders-archive-by-path" "get-files-v3-folders-get-by-path" "commands"] | sort) } | get name | first)
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

# Upload file
#
# POST /files/v3/files
# Returns: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>
# operationId: post-/files/v3/files_upload
export def "post-files-v3-files-upload" [
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
  --charset-hunch: string # Character set of the uploaded file.
  --file: string # File to be uploaded. (format: binary)
  --file-name: string # Desired name for the uploaded file.
  --folder-id: string # Either 'folderId' or 'folderPath' is required. folderId is the ID of the folder the file will be uploaded to.
  --folder-path: string # Either 'folderPath' or 'folderId' is required. This field represents the destination folder path for the uploaded file. If a path doesn't exist, the system will try to create one.
  --options: string # JSON string representing FileUploadOptions.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/v3/files"
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: charsetHunch, var: charset_hunch}, {name: file, var: file}, {name: fileName, var: file_name}, {name: folderId, var: folder_id}, {name: folderPath, var: folder_path}, {name: options, var: options}], files: [file]}
    accept: ["application/json", "*/*"]
    ok: [201]
    auth: query-hapikey
  } {
    charset_hunch: $charset_hunch, file: $file, file_name: $file_name, folder_id: $folder_id, folder_path: $folder_path, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Import a file from a URL into the file manager.
#
# POST /files/v3/files/import-from-url/async
# Returns: record<id: string, links: record>
# operationId: post-/files/v3/files/import-from-url/async_importFromUrl
export def "post-files-v3-files-import-from-url-async-import-from-url" [
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
  access: string@access-completer # PUBLIC_INDEXABLE: File is publicly accessible by anyone who has the URL. Search engines can index the file. PUBLIC_NOT_INDEXABLE: File is publicly accessible by anyone who has the URL. Search engines *can't* index the file. PRIVATE: File is NOT publicly accessible. Requires a signed URL to see content. Search engines *can't* index the file.
  duplicate_validation_scope: string@duplicate-validation-scope-completer # ENTIRE_PORTAL: Look for a duplicate file in the entire account. EXACT_FOLDER: Look for a duplicate file in the provided folder.
  duplicate_validation_strategy: string@duplicate-validation-strategy-completer # NONE: Do not run any duplicate validation. REJECT: Reject the upload if a duplicate is found. RETURN_EXISTING: If a duplicate file is found, do not upload a new file and return the found duplicate instead.
  --folder-id: string # One of folderId or folderPath is required. Destination folder ID for the uploaded file.
  --folder-path: string # One of folderPath or folderId is required. Destination folder path for the uploaded file. If the folder path does not exist, there will be an attempt to create the folder path.
  --name: string # Name to give the resulting file in the file manager.
  --overwrite: oneof<nothing, bool> # If true, it will overwrite existing files if a file with the same name exists in the given folder.
  --ttl: string # Time to live. If specified the file will be deleted after the given time frame.
  url: string # URL to download the new file from.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/v3/files/import-from-url/async"
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: duplicateValidationScope, var: duplicate_validation_scope}, {name: duplicateValidationStrategy, var: duplicate_validation_strategy}, {name: folderId, var: folder_id}, {name: folderPath, var: folder_path}, {name: name, var: name}, {name: overwrite, var: overwrite, required: true}, {name: ttl, var: ttl}, {name: url, var: url}]}
    accept: ["application/json", "*/*"]
    ok: [202]
    auth: query-hapikey
  } {
    access: $access, duplicate_validation_scope: $duplicate_validation_scope, duplicate_validation_strategy: $duplicate_validation_strategy, folder_id: $folder_id, folder_path: $folder_path, name: $name, overwrite: $overwrite, ttl: $ttl, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check import status.
#
# GET /files/v3/files/import-from-url/async/tasks/{taskId}/status
# Returns: record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>, startedAt: string, status: string, taskId: string>
# operationId: get-/files/v3/files/import-from-url/async/tasks/{taskId}/status_checkImport
export def "get-files-v3-files-import-from-url-async-tasks-status-check-import" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/files/import-from-url/async/tasks/{taskId}/status"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search files
#
# GET /files/v3/files/search
# Returns: record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>>
# operationId: get-/files/v3/files/search_doSearch
export def "get-files-v3-files-search-do-search" [
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
  --properties: list<string> # Desired file properties in the return object.
  --after: string # The maximum offset of items for a given search is 10000. Narrow your search down if you are reaching this limit.
  --before: string
  --limit: int # Number of items to return. Maximum limit is 100. (format: int32)
  --sort: list<string> # Sort files by a given field.
  --id: string # Search files by given ID.
  --created-at: string # Search files by time of creation. (format: date-time)
  --created-at-lte: string # format: date-time
  --created-at-gte: string # format: date-time
  --updated-at: string # Search files by time of latest updated. (format: date-time)
  --updated-at-lte: string # format: date-time
  --updated-at-gte: string # format: date-time
  --name: string # Search for files containing the given name.
  --path: string # Search files by path.
  --parent-folder-id: int # Search files within given folder ID. (format: int64)
  --size: int # Query by file size. (format: int64)
  --height: int # Search files by height of image or video. (format: int32)
  --width: int # Search files by width of image or video. (format: int32)
  --encoding: string # Search files with specified encoding.
  --type: string # Filter by provided file type.
  --extension: string # Search files by given extension.
  --url: string # Search for given URL
  --is-usable-in-content: oneof<nothing, bool> # If true shows files that have been marked to be used in new content. It false shows files that should not be used in new content.
  --allows-anonymous-access: oneof<nothing, bool> # If 'true' will show private files; if 'false' will show public files
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/files/search"
    query: [{name: properties, var: properties, style: multi}, {name: after, var: after}, {name: before, var: before}, {name: limit, var: limit}, {name: sort, var: sort, style: multi}, {name: id, var: id}, {name: createdAt, var: created_at}, {name: createdAtLte, var: created_at_lte}, {name: createdAtGte, var: created_at_gte}, {name: updatedAt, var: updated_at}, {name: updatedAtLte, var: updated_at_lte}, {name: updatedAtGte, var: updated_at_gte}, {name: name, var: name}, {name: path, var: path}, {name: parentFolderId, var: parent_folder_id}, {name: size, var: size}, {name: height, var: height}, {name: width, var: width}, {name: encoding, var: encoding}, {name: type, var: type}, {name: extension, var: extension}, {name: url, var: url}, {name: isUsableInContent, var: is_usable_in_content}, {name: allowsAnonymousAccess, var: allows_anonymous_access}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    properties: $properties, after: $after, before: $before, limit: $limit, sort: $sort, id: $id, created_at: $created_at, created_at_lte: $created_at_lte, created_at_gte: $created_at_gte, updated_at: $updated_at, updated_at_lte: $updated_at_lte, updated_at_gte: $updated_at_gte, name: $name, path: $path, parent_folder_id: $parent_folder_id, size: $size, height: $height, width: $width, encoding: $encoding, type: $type, extension: $extension, url: $url, is_usable_in_content: $is_usable_in_content, allows_anonymous_access: $allows_anonymous_access
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete file
#
# DELETE /files/v3/files/{fileId}
# operationId: delete-/files/v3/files/{fileId}_archive
export def "delete-files-v3-files-archive" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/v3/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    accept: ["*/*"]
    ok: [204]
    auth: query-hapikey
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get file.
#
# GET /files/v3/files/{fileId}
# Returns: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>
# operationId: get-/files/v3/files/{fileId}_getById
export def "get-files-v3-files-get-by-id" [
  file_id: string
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
  --properties: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: properties, var: properties, style: multi}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    file_id: $file_id, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# update file properties
#
# PATCH /files/v3/files/{fileId}
# Returns: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>
# operationId: patch-/files/v3/files/{fileId}_updateProperties
export def "patch-files-v3-files-update-properties" [
  file_id: string
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
  --access: string@access-completer # NONE: Do not run any duplicate validation. REJECT: Reject the upload if a duplicate is found. RETURN_EXISTING: If a duplicate file is found, do not upload a new file and return the found duplicate instead.
  --is-usable-in-content: oneof<nothing, bool> # Mark weather the file should be used in new content or not.
  --name: string # New name for the file.
  --parent-folder-id: string # Folder ID where the file should be moved to. folderId and folderPath cannot be set at the same time.
  --parent-folder-path: string # Folder path where the file should be moved to. folderId and folderPath cannot be set at the same time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/files/v3/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: access, var: access}, {name: isUsableInContent, var: is_usable_in_content}, {name: name, var: name}, {name: parentFolderId, var: parent_folder_id}, {name: parentFolderPath, var: parent_folder_path}]}
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: query-hapikey
  } {
    file_id: $file_id, access: $access, is_usable_in_content: $is_usable_in_content, name: $name, parent_folder_id: $parent_folder_id, parent_folder_path: $parent_folder_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace file.
#
# PUT /files/v3/files/{fileId}
# Returns: record<access: string, archived: bool, archivedAt: string, createdAt: string, defaultHostingUrl: string, encoding: string, extension: string, height: int, id: string, isUsableInContent: bool, name: string, parentFolderId: string, path: string, size: int, type: string, updatedAt: string, url: string, width: int>
# operationId: put-/files/v3/files/{fileId}_replace
export def "put-files-v3-files-replace" [
  file_id: string
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
  --charset-hunch: string # Character set of given file data.
  --file: string # File data that will replace existing file in the file manager. (format: binary)
  --options: string # JSON String representing FileReplaceOptions
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/files/v3/files/{fileId}"
    path_params: [{name: fileId, var: file_id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: charsetHunch, var: charset_hunch}, {name: file, var: file}, {name: options, var: options}], files: [file]}
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: query-hapikey
  } {
    file_id: $file_id, charset_hunch: $charset_hunch, file: $file, options: $options
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GDPR delete
#
# DELETE /files/v3/files/{fileId}/gdpr-delete
# operationId: delete-/files/v3/files/{fileId}/gdpr-delete_archiveGDPR
export def "delete-files-v3-files-gdpr-delete-archive-gdpr" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/v3/files/{fileId}/gdpr-delete"
    path_params: [{name: fileId, var: file_id}]
    accept: ["*/*"]
    ok: [204]
    auth: query-hapikey
  } {
    file_id: $file_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get signed URL to access private file.
#
# GET /files/v3/files/{fileId}/signed-url
# Returns: record<expiresAt: string, extension: string, height: int, name: string, size: int, type: string, url: string, width: int>
# operationId: get-/files/v3/files/{fileId}/signed-url_getSignedUrl
export def "get-files-v3-files-signed-url-get-signed-url" [
  file_id: string
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
  --size: string@size-completer # For image files. This will resize the image to the desired size before sharing. Does not affect the original file, just the file served by this signed URL.
  --expiration-seconds: int # How long in seconds the link will provide access to the file. (format: int64)
  --upscale: oneof<nothing, bool> # If size is provided, this will upscale the image to fit the size dimensions.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/files/{fileId}/signed-url"
    path_params: [{name: fileId, var: file_id}]
    query: [{name: size, var: size}, {name: expirationSeconds, var: expiration_seconds}, {name: upscale, var: upscale}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    file_id: $file_id, size: $size, expiration_seconds: $expiration_seconds, upscale: $upscale
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create folder.
#
# POST /files/v3/folders
# Returns: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>
# operationId: post-/files/v3/folders_create
export def "post-files-v3-folders-create" [
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
  name: string # Desired name for the folder.
  --parent-folder-id: string # Folder ID of the parent of the created folder. If not specified, the folder will be created at the root level. parentFolderId and parentFolderPath cannot be set at the same time.
  --parent-path: string # Path of the parent of the created folder. If not specified the folder will be created at the root level. parentFolderPath and parentFolderId cannot be set at the same time.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/v3/folders"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: parentFolderId, var: parent_folder_id}, {name: parentPath, var: parent_path}]}
    accept: ["application/json", "*/*"]
    ok: [201]
    auth: query-hapikey
  } {
    name: $name, parent_folder_id: $parent_folder_id, parent_path: $parent_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Search folders
#
# GET /files/v3/folders/search
# Returns: record<paging: record<next: record<after: string, link: string>, prev: record<before: string, link: string>>, results: table<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>>
# operationId: get-/files/v3/folders/search_doSearch
export def "get-files-v3-folders-search-do-search" [
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
  --properties: list<string> # Properties that should be included in the returned folders.
  --after: string # The maximum offset of items for a given search is 10000. Narrow your search down if you are reaching this limit.
  --before: string
  --limit: int # Limit of results to return. Max limit is 100. (format: int32)
  --sort: list<string> # Sort results by given property. For example -name sorts by name field descending, name sorts by name field ascending.
  --id: string # Search folder by given ID.
  --created-at: string # Search for folders with the given creation timestamp. (format: date-time)
  --created-at-lte: string # format: date-time
  --created-at-gte: string # format: date-time
  --updated-at: string # Search for folder at given update timestamp. (format: date-time)
  --updated-at-lte: string # format: date-time
  --updated-at-gte: string # format: date-time
  --name: string # Search for folders containing the specified name.
  --path: string # Search for folders by path.
  --parent-folder-id: int # Search for folders with the given parent folder ID. (format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/folders/search"
    query: [{name: properties, var: properties, style: multi}, {name: after, var: after}, {name: before, var: before}, {name: limit, var: limit}, {name: sort, var: sort, style: multi}, {name: id, var: id}, {name: createdAt, var: created_at}, {name: createdAtLte, var: created_at_lte}, {name: createdAtGte, var: created_at_gte}, {name: updatedAt, var: updated_at}, {name: updatedAtLte, var: updated_at_lte}, {name: updatedAtGte, var: updated_at_gte}, {name: name, var: name}, {name: path, var: path}, {name: parentFolderId, var: parent_folder_id}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    properties: $properties, after: $after, before: $before, limit: $limit, sort: $sort, id: $id, created_at: $created_at, created_at_lte: $created_at_lte, created_at_gte: $created_at_gte, updated_at: $updated_at, updated_at_lte: $updated_at_lte, updated_at_gte: $updated_at_gte, name: $name, path: $path, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update folder properties
#
# POST /files/v3/folders/update/async
# Returns: record<id: string, links: record>
# operationId: post-/files/v3/folders/update/async_updateProperties
export def "post-files-v3-folders-update-async-update-properties" [
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
  id: string # Id of the folder to change.
  --name: string # New name. If specified the folder's name and fullPath will change. All children of the folder will be updated accordingly.
  --parent-folder-id: int # New parent folder ID. If changed, the folder and all it's children will be moved into the specified folder. parentFolderId and parentFolderPath cannot be specified at the same time. (format: int64)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/files/v3/folders/update/async"
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: name, var: name}, {name: parentFolderId, var: parent_folder_id}]}
    accept: ["application/json", "*/*"]
    ok: [202]
    auth: query-hapikey
  } {
    id: $id, name: $name, parent_folder_id: $parent_folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check folder update status.
#
# GET /files/v3/folders/update/async/tasks/{taskId}/status
# Returns: record<completedAt: string, errors: table<category: record, context: record, errors: list, id: string, links: record, message: string, status: string, subCategory: record>, links: record, numErrors: int, requestedAt: string, result: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>, startedAt: string, status: string, taskId: string>
# operationId: get-/files/v3/folders/update/async/tasks/{taskId}/status_checkUpdateStatus
export def "get-files-v3-folders-update-async-tasks-status-check-update-status" [
  task_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/folders/update/async/tasks/{taskId}/status"
    path_params: [{name: taskId, var: task_id}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: query-hapikey
  } {
    task_id: $task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete folder.
#
# DELETE /files/v3/folders/{folderId}
# operationId: delete-/files/v3/folders/{folderId}_archive
export def "delete-files-v3-folders-archive" [
  folder_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/v3/folders/{folderId}"
    path_params: [{name: folderId, var: folder_id}]
    accept: ["*/*"]
    ok: [204]
    auth: query-hapikey
  } {
    folder_id: $folder_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get folder
#
# GET /files/v3/folders/{folderId}
# Returns: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>
# operationId: get-/files/v3/folders/{folderId}_getById
export def "get-files-v3-folders-get-by-id" [
  folder_id: string
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
  --properties: list<string> # Properties to set on returned folder.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/folders/{folderId}"
    path_params: [{name: folderId, var: folder_id}]
    query: [{name: properties, var: properties, style: multi}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    folder_id: $folder_id, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Delete folder.
#
# DELETE /files/v3/folders/{folderPath}
# operationId: delete-/files/v3/folders/{folderPath}_archiveByPath
export def "delete-files-v3-folders-archive-by-path" [
  folder_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  http-request {
    method: delete
    path: "/files/v3/folders/{folderPath}"
    path_params: [{name: folderPath, var: folder_path}]
    accept: ["*/*"]
    ok: [204]
    auth: query-hapikey
  } {
    folder_path: $folder_path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get folder.
#
# GET /files/v3/folders/{folderPath}
# Returns: record<archived: bool, archivedAt: string, createdAt: string, id: string, name: string, parentFolderId: string, path: string, updatedAt: string>
# operationId: get-/files/v3/folders/{folderPath}_getByPath
export def "get-files-v3-folders-get-by-path" [
  folder_path: string
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
  --properties: list<string> # Properties to set on returned folder.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/files/v3/folders/{folderPath}"
    path_params: [{name: folderPath, var: folder_path}]
    query: [{name: properties, var: properties, style: multi}]
    accept: ["application/json", "*/*"]
    ok: [200]
    auth: private-app-legacy
  } {
    folder_path: $folder_path, properties: $properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
