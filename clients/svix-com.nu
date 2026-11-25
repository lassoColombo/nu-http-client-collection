# Auto-generated client for Svix API v1.4
# Source: https://api.apis.guru/v2/specs/svix.com/1.4/openapi.json
# Auth: --token flag or $env.SVIX_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "SVIX_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["ascending" "descending"] }
def status-completer [] { ["0" "1" "2" "3"] }
def status-code-class-completer [] { ["0" "100" "200" "300" "400" "500"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-applications-api-v1-app-get: "record<data: table<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string>"
    create-application-api-v1-app-post: "record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>"
    get-application-api-v1-app-app-id-get: "record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>"
    update-application-api-v1-app-app-id-put: "record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>"
    list-attempts-by-endpoint-api-v1-app-app-id-attempt-endpoint-endpoint-id-get: "record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>"
    list-attempts-by-msg-api-v1-app-app-id-attempt-msg-msg-id-get: "record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>"
    list-endpoints-api-v1-app-app-id-endpoint-get: "record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>, done: bool, iterator: string, prevIterator: string>"
    create-endpoint-api-v1-app-app-id-endpoint-post: "record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>"
    get-endpoint-api-v1-app-app-id-endpoint-endpoint-id-get: "record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>"
    update-endpoint-api-v1-app-app-id-endpoint-endpoint-id-put: "record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>"
    get-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-get: "record<headers: record, sensitive: list<string>>"
    list-attempted-messages-api-v1-app-app-id-endpoint-endpoint-id-msg-get: "record<data: table<channels: list, eventId: string, eventType: string, id: string, nextAttempt: string, payload: record, status: int, timestamp: string>, done: bool, iterator: string, prevIterator: string>"
    recover-failed-webhooks-api-v1-app-app-id-endpoint-endpoint-id-recover-post: "record<id: string, status: string, task: string>"
    replay-missing-webhooks-api-v1-app-app-id-endpoint-endpoint-id-replay-missing-post: "record<id: string, status: string, task: string>"
    get-endpoint-secret-api-v1-app-app-id-endpoint-endpoint-id-secret-get: "record<key: string>"
    get-endpoint-stats-api-v1-app-app-id-endpoint-endpoint-id-stats-get: "record<fail: int, pending: int, sending: int, success: int>"
    get-endpoint-transformation-api-v1-app-app-id-endpoint-endpoint-id-transformation-get: "record<code: string, enabled: bool>"
    list-integrations-api-v1-app-app-id-integration-get: "record<data: table<createdAt: string, id: string, name: string, updatedAt: string>, done: bool, iterator: string>"
    create-integration-api-v1-app-app-id-integration-post: "record<createdAt: string, id: string, name: string, updatedAt: string>"
    get-integration-api-v1-app-app-id-integration-integ-id-get: "record<createdAt: string, id: string, name: string, updatedAt: string>"
    update-integration-api-v1-app-app-id-integration-integ-id-put: "record<createdAt: string, id: string, name: string, updatedAt: string>"
    get-integration-key-api-v1-app-app-id-integration-integ-id-key-get: "record<key: string>"
    rotate-integration-key-api-v1-app-app-id-integration-integ-id-key-rotate-post: "record<key: string>"
    list-messages-api-v1-app-app-id-msg-get: "record<data: table<channels: list, eventId: string, eventType: string, id: string, payload: record, timestamp: string>, done: bool, iterator: string, prevIterator: string>"
    create-message-api-v1-app-app-id-msg-post: "record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string>"
    get-message-api-v1-app-app-id-msg-msg-id-get: "record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string>"
    list-attempts-api-v1-app-app-id-msg-msg-id-attempt-get: "record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>"
    get-attempt-api-v1-app-app-id-msg-msg-id-attempt-attempt-id-get: "record<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>"
    list-attempted-destinations-api-v1-app-app-id-msg-msg-id-endpoint-get: "record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, nextAttempt: string, rateLimit: int, status: int, uid: string, url: string, version: int>, done: bool, iterator: string>"
    list-attempts-for-endpoint-api-v1-app-app-id-msg-msg-id-endpoint-endpoint-id-attempt-get: "record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>"
    get-app-portal-access-api-v1-auth-app-portal-access-app-id-post: "record<token: string, url: string>"
    get-dashboard-access-api-v1-auth-dashboard-access-app-id-post: "record<token: string, url: string>"
    list-background-tasks-api-v1-background-task-get: "record<data: table<data: record, id: string, status: string, task: string>, done: bool, iterator: string, prevIterator: string>"
    get-background-task-api-v1-background-task-task-id-get: "record<data: record, id: string, status: string, task: string>"
    list-event-types-api-v1-event-type-get: "record<data: table<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>, done: bool, iterator: string, prevIterator: string>"
    create-event-type-api-v1-event-type-post: "record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>"
    get-event-type-api-v1-event-type-event-type-name-get: "record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>"
    update-event-type-api-v1-event-type-event-type-name-put: "record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-applications-api-v1-app-get" "create-application-api-v1-app-post" "delete-application-api-v1-app-app-id-delete" "get-application-api-v1-app-app-id-get" "update-application-api-v1-app-app-id-put" "list-attempts-by-endpoint-api-v1-app-app-id-attempt-endpoint-endpoint-id-get" "list-attempts-by-msg-api-v1-app-app-id-attempt-msg-msg-id-get" "list-endpoints-api-v1-app-app-id-endpoint-get" "create-endpoint-api-v1-app-app-id-endpoint-post" "delete-endpoint-api-v1-app-app-id-endpoint-endpoint-id-delete" "get-endpoint-api-v1-app-app-id-endpoint-endpoint-id-get" "update-endpoint-api-v1-app-app-id-endpoint-endpoint-id-put" "get-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-get" "patch-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-patch" "update-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-put" "list-attempted-messages-api-v1-app-app-id-endpoint-endpoint-id-msg-get" "recover-failed-webhooks-api-v1-app-app-id-endpoint-endpoint-id-recover-post" "replay-missing-webhooks-api-v1-app-app-id-endpoint-endpoint-id-replay-missing-post" "get-endpoint-secret-api-v1-app-app-id-endpoint-endpoint-id-secret-get" "rotate-endpoint-secret-api-v1-app-app-id-endpoint-endpoint-id-secret-rotate-post" "get-endpoint-stats-api-v1-app-app-id-endpoint-endpoint-id-stats-get" "get-endpoint-transformation-api-v1-app-app-id-endpoint-endpoint-id-transformation-get" "set-endpoint-transformation-api-v1-app-app-id-endpoint-endpoint-id-transformation-patch" "list-integrations-api-v1-app-app-id-integration-get" "create-integration-api-v1-app-app-id-integration-post" "delete-integration-api-v1-app-app-id-integration-integ-id-delete" "get-integration-api-v1-app-app-id-integration-integ-id-get" "update-integration-api-v1-app-app-id-integration-integ-id-put" "get-integration-key-api-v1-app-app-id-integration-integ-id-key-get" "rotate-integration-key-api-v1-app-app-id-integration-integ-id-key-rotate-post" "list-messages-api-v1-app-app-id-msg-get" "create-message-api-v1-app-app-id-msg-post" "get-message-api-v1-app-app-id-msg-msg-id-get" "list-attempts-api-v1-app-app-id-msg-msg-id-attempt-get" "get-attempt-api-v1-app-app-id-msg-msg-id-attempt-attempt-id-get" "expunge-attempt-content-api-v1-app-app-id-msg-msg-id-attempt-attempt-id-content-delete" "expunge-message-payload-api-v1-app-app-id-msg-msg-id-content-delete" "list-attempted-destinations-api-v1-app-app-id-msg-msg-id-endpoint-get" "list-attempts-for-endpoint-api-v1-app-app-id-msg-msg-id-endpoint-endpoint-id-attempt-get" "resend-webhook-api-v1-app-app-id-msg-msg-id-endpoint-endpoint-id-resend-post" "get-app-portal-access-api-v1-auth-app-portal-access-app-id-post" "expire-all-api-v1-auth-app-app-id-expire-all-post" "get-dashboard-access-api-v1-auth-dashboard-access-app-id-post" "logout-api-v1-auth-logout-post" "list-background-tasks-api-v1-background-task-get" "get-background-task-api-v1-background-task-task-id-get" "list-event-types-api-v1-event-type-get" "create-event-type-api-v1-event-type-post" "delete-event-type-api-v1-event-type-event-type-name-delete" "get-event-type-api-v1-event-type-event-type-name-get" "update-event-type-api-v1-event-type-event-type-name-put" "health-api-v1-health-get" "commands"] | sort) } | get name | first)
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

# List Applications
#
# GET /api/v1/app/
# Returns: record<data: table<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_applications_api_v1_app__get
export def "list-applications-api-v1-app-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. app_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string@order-completer # default: descending
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/"
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: order, var: order}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    iterator: $iterator, limit: $limit, order: $order, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Application
#
# POST /api/v1/app/
# Returns: record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>
# operationId: create_application_api_v1_app__post
export def "create-application-api-v1-app-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-if-exists: oneof<nothing, bool> # Get an existing application, or create a new one if doesn't exist. It's two separate functions in the libs. (default: false)
  --idempotency-key: string # The request's idempotency key (nullable)
  --metadata: record # nullable
  name: string # e.g. My first application
  --rate-limit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the application (nullable, e.g. unique-app-identifier)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/"
    query: [{name: get_if_exists, var: get_if_exists}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: metadata, var: metadata}, {name: name, var: name}, {name: rateLimit, var: rate_limit}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    get_if_exists: $get_if_exists, idempotency_key: $idempotency_key, metadata: $metadata, name: $name, rate_limit: $rate_limit, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Application
#
# DELETE /api/v1/app/{app_id}/
# operationId: delete_application_api_v1_app__app_id___delete
export def "delete-application-api-v1-app-app-id-delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/app/{app_id}/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Application
#
# GET /api/v1/app/{app_id}/
# Returns: record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>
# operationId: get_application_api_v1_app__app_id___get
export def "get-application-api-v1-app-app-id-get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Application
#
# PUT /api/v1/app/{app_id}/
# Returns: record<createdAt: string, id: string, metadata: record, name: string, rateLimit: int, uid: string, updatedAt: string>
# operationId: update_application_api_v1_app__app_id___put
export def "update-application-api-v1-app-app-id-put" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --metadata: record # nullable
  name: string # e.g. My first application
  --rate-limit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the application (nullable, e.g. unique-app-identifier)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/app/{app_id}/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: metadata, var: metadata}, {name: name, var: name}, {name: rateLimit, var: rate_limit}, {name: uid, var: uid}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key, metadata: $metadata, name: $name, rate_limit: $rate_limit, uid: $uid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempts By Endpoint
#
# GET /api/v1/app/{app_id}/attempt/endpoint/{endpoint_id}/
# Returns: record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_attempts_by_endpoint_api_v1_app__app_id__attempt_endpoint__endpoint_id___get
export def "list-attempts-by-endpoint-api-v1-app-app-id-attempt-endpoint-endpoint-id-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --status: int@status-completer
  --status-code-class: int@status-code-class-completer
  --event-types: list<string> # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/attempt/endpoint/{endpoint_id}/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: status, var: status}, {name: status_code_class, var: status_code_class}, {name: event_types, var: event_types, style: multi}, {name: channel, var: channel}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, iterator: $iterator, limit: $limit, status: $status, status_code_class: $status_code_class, event_types: $event_types, channel: $channel, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempts By Msg
#
# GET /api/v1/app/{app_id}/attempt/msg/{msg_id}/
# Returns: record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_attempts_by_msg_api_v1_app__app_id__attempt_msg__msg_id___get
export def "list-attempts-by-msg-api-v1-app-app-id-attempt-msg-msg-id-get" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --endpoint-id: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --status: int@status-completer
  --status-code-class: int@status-code-class-completer
  --event-types: list<string> # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/attempt/msg/{msg_id}/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}]
    query: [{name: endpoint_id, var: endpoint_id}, {name: iterator, var: iterator}, {name: limit, var: limit}, {name: status, var: status}, {name: status_code_class, var: status_code_class}, {name: event_types, var: event_types, style: multi}, {name: channel, var: channel}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, endpoint_id: $endpoint_id, iterator: $iterator, limit: $limit, status: $status, status_code_class: $status_code_class, event_types: $event_types, channel: $channel, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Endpoints
#
# GET /api/v1/app/{app_id}/endpoint/
# Returns: record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>, done: bool, iterator: string, prevIterator: string>
# operationId: list_endpoints_api_v1_app__app_id__endpoint__get
export def "list-endpoints-api-v1-app-app-id-endpoint-get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string@order-completer # default: descending
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/"
    path_params: [{name: app_id, var: app_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: order, var: order}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, iterator: $iterator, limit: $limit, order: $order, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Endpoint
#
# POST /api/v1/app/{app_id}/endpoint/
# Returns: record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>
# operationId: create_endpoint_api_v1_app__app_id__endpoint__post
export def "create-endpoint-api-v1-app-app-id-endpoint-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --channels: list<string> # List of message channels this endpoint listens to (omit for all) (nullable, e.g. [project_123, group_2])
  --description: string # default: "", e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filter-types: list<string> # nullable, e.g. [user.signup, user.deleted]
  --metadata: record # nullable
  --rate-limit: int # nullable, e.g. 1000
  --secret: string # The endpoint's verification secret. If `null` is passed, a secret is automatically generated. Format: `base64` encoded random bytes optionally prefixed with `whsec_`. Recommended size: 24. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
  --uid: string # Optional unique identifier for the endpoint (nullable, e.g. unique-endpoint-identifier)
  url: string # format: uri, e.g. https://example.com/webhook/
  version: int # e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/endpoint/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}, {name: description, var: description}, {name: disabled, var: disabled}, {name: filterTypes, var: filter_types}, {name: metadata, var: metadata}, {name: rateLimit, var: rate_limit}, {name: secret, var: secret}, {name: uid, var: uid}, {name: url, var: url}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key, channels: $channels, description: $description, disabled: $disabled, filter_types: $filter_types, metadata: $metadata, rate_limit: $rate_limit, secret: $secret, uid: $uid, url: $url, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Endpoint
#
# DELETE /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# operationId: delete_endpoint_api_v1_app__app_id__endpoint__endpoint_id___delete
export def "delete-endpoint-api-v1-app-app-id-endpoint-endpoint-id-delete" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Endpoint
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# Returns: record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>
# operationId: get_endpoint_api_v1_app__app_id__endpoint__endpoint_id___get
export def "get-endpoint-api-v1-app-app-id-endpoint-endpoint-id-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Endpoint
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}/
# Returns: record<channels: list<string>, createdAt: string, description: string, disabled: bool, filterTypes: list<string>, id: string, metadata: record, rateLimit: int, uid: string, updatedAt: string, url: string, version: int>
# operationId: update_endpoint_api_v1_app__app_id__endpoint__endpoint_id___put
export def "update-endpoint-api-v1-app-app-id-endpoint-endpoint-id-put" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --channels: list<string> # List of message channels this endpoint listens to (omit for all) (nullable, e.g. [project_123, group_2])
  --description: string # default: "", e.g. An example endpoint name
  --disabled: oneof<nothing, bool> # default: false, e.g. false
  --filter-types: list<string> # nullable, e.g. [user.signup, user.deleted]
  --metadata: record # nullable
  --rate-limit: int # nullable, e.g. 1000
  --uid: string # Optional unique identifier for the endpoint (nullable, e.g. unique-endpoint-identifier)
  url: string # format: uri, e.g. https://example.com/webhook/
  version: int # e.g. 1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: channels, var: channels}, {name: description, var: description}, {name: disabled, var: disabled}, {name: filterTypes, var: filter_types}, {name: metadata, var: metadata}, {name: rateLimit, var: rate_limit}, {name: uid, var: uid}, {name: url, var: url}, {name: version, var: version}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, channels: $channels, description: $description, disabled: $disabled, filter_types: $filter_types, metadata: $metadata, rate_limit: $rate_limit, uid: $uid, url: $url, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Endpoint Headers
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# Returns: record<headers: record, sensitive: list<string>>
# operationId: get_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__get
export def "get-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch Endpoint Headers
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# operationId: patch_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__patch
export def "patch-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-patch" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: headers, var: headers}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, headers: $headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Endpoint Headers
#
# PUT /api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/
# operationId: update_endpoint_headers_api_v1_app__app_id__endpoint__endpoint_id__headers__put
export def "update-endpoint-headers-api-v1-app-app-id-endpoint-endpoint-id-headers-put" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  headers: record # e.g. {X-Example: 123, X-Foobar: Bar}
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/headers/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: headers, var: headers}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, headers: $headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempted Messages
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/msg/
# Returns: record<data: table<channels: list, eventId: string, eventType: string, id: string, nextAttempt: string, payload: record, status: int, timestamp: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_attempted_messages_api_v1_app__app_id__endpoint__endpoint_id__msg__get
export def "list-attempted-messages-api-v1-app-app-id-endpoint-endpoint-id-msg-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/msg/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: channel, var: channel}, {name: status, var: status}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, iterator: $iterator, limit: $limit, channel: $channel, status: $status, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Recover Failed Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/recover/
# Returns: record<id: string, status: string, task: string>
# operationId: recover_failed_webhooks_api_v1_app__app_id__endpoint__endpoint_id__recover__post
export def "recover-failed-webhooks-api-v1-app-app-id-endpoint-endpoint-id-recover-post" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/recover/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: since, var: since}, {name: until, var: until}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, since: $since, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replay Missing Webhooks
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/replay-missing/
# Returns: record<id: string, status: string, task: string>
# operationId: replay_missing_webhooks_api_v1_app__app_id__endpoint__endpoint_id__replay_missing__post
export def "replay-missing-webhooks-api-v1-app-app-id-endpoint-endpoint-id-replay-missing-post" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  since: string # format: date-time
  --until: string # nullable, format: date-time
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/replay-missing/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: since, var: since}, {name: until, var: until}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, since: $since, until: $until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Endpoint Secret
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/
# Returns: record<key: string>
# operationId: get_endpoint_secret_api_v1_app__app_id__endpoint__endpoint_id__secret__get
export def "get-endpoint-secret-api-v1-app-app-id-endpoint-endpoint-id-secret-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotate Endpoint Secret
#
# POST /api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/rotate/
# operationId: rotate_endpoint_secret_api_v1_app__app_id__endpoint__endpoint_id__secret_rotate__post
export def "rotate-endpoint-secret-api-v1-app-app-id-endpoint-endpoint-id-secret-rotate-post" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --key: string # The endpoint's verification secret. If `null` is passed, a secret is automatically generated. Format: `base64` encoded random bytes optionally prefixed with `whsec_`. Recommended size: 24. (nullable, e.g. whsec_C2FVsBQIhrscChlQIMV+b5sSYspob7oD)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/secret/rotate/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Endpoint Stats
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/stats/
# Returns: record<fail: int, pending: int, sending: int, success: int>
# operationId: get_endpoint_stats_api_v1_app__app_id__endpoint__endpoint_id__stats__get
export def "get-endpoint-stats-api-v1-app-app-id-endpoint-endpoint-id-stats-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # nullable, format: date-time
  --until: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/stats/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    query: [{name: since, var: since}, {name: until, var: until}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, since: $since, until: $until, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Endpoint Transformation
#
# GET /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/
# Returns: record<code: string, enabled: bool>
# operationId: get_endpoint_transformation_api_v1_app__app_id__endpoint__endpoint_id__transformation__get
export def "get-endpoint-transformation-api-v1-app-app-id-endpoint-endpoint-id-transformation-get" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set Endpoint Transformation
#
# PATCH /api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/
# operationId: set_endpoint_transformation_api_v1_app__app_id__endpoint__endpoint_id__transformation__patch
export def "set-endpoint-transformation-api-v1-app-app-id-endpoint-endpoint-id-transformation-patch" [
  app_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --code: string # nullable
  --enabled: oneof<nothing, bool> # default: false
]: any -> any {
  $in | http-request {
    method: patch
    path: "/api/v1/app/{app_id}/endpoint/{endpoint_id}/transformation/"
    path_params: [{name: app_id, var: app_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: code, var: code}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key, code: $code, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Integrations
#
# GET /api/v1/app/{app_id}/integration/
# Returns: record<data: table<createdAt: string, id: string, name: string, updatedAt: string>, done: bool, iterator: string>
# operationId: list_integrations_api_v1_app__app_id__integration__get
export def "list-integrations-api-v1-app-app-id-integration-get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. integ_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/integration/"
    path_params: [{name: app_id, var: app_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, iterator: $iterator, limit: $limit, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Integration
#
# POST /api/v1/app/{app_id}/integration/
# Returns: record<createdAt: string, id: string, name: string, updatedAt: string>
# operationId: create_integration_api_v1_app__app_id__integration__post
export def "create-integration-api-v1-app-app-id-integration-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  name: string # e.g. Example Integration
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/integration/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Integration
#
# DELETE /api/v1/app/{app_id}/integration/{integ_id}/
# operationId: delete_integration_api_v1_app__app_id__integration__integ_id___delete
export def "delete-integration-api-v1-app-app-id-integration-integ-id-delete" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/app/{app_id}/integration/{integ_id}/"
    path_params: [{name: app_id, var: app_id}, {name: integ_id, var: integ_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, integ_id: $integ_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Integration
#
# GET /api/v1/app/{app_id}/integration/{integ_id}/
# Returns: record<createdAt: string, id: string, name: string, updatedAt: string>
# operationId: get_integration_api_v1_app__app_id__integration__integ_id___get
export def "get-integration-api-v1-app-app-id-integration-integ-id-get" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/integration/{integ_id}/"
    path_params: [{name: app_id, var: app_id}, {name: integ_id, var: integ_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, integ_id: $integ_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Integration
#
# PUT /api/v1/app/{app_id}/integration/{integ_id}/
# Returns: record<createdAt: string, id: string, name: string, updatedAt: string>
# operationId: update_integration_api_v1_app__app_id__integration__integ_id___put
export def "update-integration-api-v1-app-app-id-integration-integ-id-put" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  name: string # e.g. Example Integration
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/app/{app_id}/integration/{integ_id}/"
    path_params: [{name: app_id, var: app_id}, {name: integ_id, var: integ_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, integ_id: $integ_id, idempotency_key: $idempotency_key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Integration Key
#
# GET /api/v1/app/{app_id}/integration/{integ_id}/key/
# Returns: record<key: string>
# operationId: get_integration_key_api_v1_app__app_id__integration__integ_id__key__get
export def "get-integration-key-api-v1-app-app-id-integration-integ-id-key-get" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/integration/{integ_id}/key/"
    path_params: [{name: app_id, var: app_id}, {name: integ_id, var: integ_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, integ_id: $integ_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rotate Integration Key
#
# POST /api/v1/app/{app_id}/integration/{integ_id}/key/rotate/
# Returns: record<key: string>
# operationId: rotate_integration_key_api_v1_app__app_id__integration__integ_id__key_rotate__post
export def "rotate-integration-key-api-v1-app-app-id-integration-integ-id-key-rotate-post" [
  app_id: string
  integ_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/app/{app_id}/integration/{integ_id}/key/rotate/"
    path_params: [{name: app_id, var: app_id}, {name: integ_id, var: integ_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, integ_id: $integ_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Messages
#
# GET /api/v1/app/{app_id}/msg/
# Returns: record<data: table<channels: list, eventId: string, eventType: string, id: string, payload: record, timestamp: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_messages_api_v1_app__app_id__msg__get
export def "list-messages-api-v1-app-app-id-msg-get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msg_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --event-types: list<string> # nullable
  --channel: string # nullable, e.g. project_1337
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/"
    path_params: [{name: app_id, var: app_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: event_types, var: event_types, style: multi}, {name: channel, var: channel}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, iterator: $iterator, limit: $limit, event_types: $event_types, channel: $channel, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Message
#
# POST /api/v1/app/{app_id}/msg/
# Returns: record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string>
# operationId: create_message_api_v1_app__app_id__msg__post
export def "create-message-api-v1-app-app-id-msg-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-content: oneof<nothing, bool> # default: true
  --idempotency-key: string # The request's idempotency key (nullable)
  --application: record # shape: {metadata?: record, name: string, rateLimit?: int, uid?: string}
  --channels: list<string> # List of free-form identifiers that endpoints can filter by (nullable, e.g. [project_123, group_2])
  --event-id: string # Optional unique identifier for the message (nullable, e.g. evt_pNZKtWg8Azow)
  event_type: string # e.g. user.signup
  payload: record # e.g. {email: test@example.com, username: test_user}
  --payload-retention-period: int # The retention period for the payload (in days). (default: 90, e.g. 90)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/app/{app_id}/msg/"
    path_params: [{name: app_id, var: app_id}]
    query: [{name: with_content, var: with_content}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: application, var: application}, {name: channels, var: channels}, {name: eventId, var: event_id}, {name: eventType, var: event_type}, {name: payload, var: payload}, {name: payloadRetentionPeriod, var: payload_retention_period}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    app_id: $app_id, with_content: $with_content, idempotency_key: $idempotency_key, application: $application, channels: $channels, event_id: $event_id, event_type: $event_type, payload: $payload, payload_retention_period: $payload_retention_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Message
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/
# Returns: record<channels: list<string>, eventId: string, eventType: string, id: string, payload: record, timestamp: string>
# operationId: get_message_api_v1_app__app_id__msg__msg_id___get
export def "get-message-api-v1-app-app-id-msg-msg-id-get" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/{msg_id}/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempts
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/attempt/
# DEPRECATED
# Returns: record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_attempts_api_v1_app__app_id__msg__msg_id__attempt__get
@deprecated
export def "list-attempts-api-v1-app-app-id-msg-msg-id-attempt-get" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --endpoint-id: string # nullable, e.g. ep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --event-types: list<string> # nullable
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/{msg_id}/attempt/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: endpoint_id, var: endpoint_id}, {name: event_types, var: event_types, style: multi}, {name: channel, var: channel}, {name: status, var: status}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, iterator: $iterator, limit: $limit, endpoint_id: $endpoint_id, event_types: $event_types, channel: $channel, status: $status, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Attempt
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/
# Returns: record<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>
# operationId: get_attempt_api_v1_app__app_id__msg__msg_id__attempt__attempt_id___get
export def "get-attempt-api-v1-app-app-id-msg-msg-id-attempt-attempt-id-get" [
  app_id: string
  msg_id: string
  attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}, {name: attempt_id, var: attempt_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, attempt_id: $attempt_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attempt response body
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/content/
# operationId: expunge_attempt_content_api_v1_app__app_id__msg__msg_id__attempt__attempt_id__content__delete
export def "expunge-attempt-content-api-v1-app-app-id-msg-msg-id-attempt-attempt-id-content-delete" [
  app_id: string
  msg_id: string
  attempt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/app/{app_id}/msg/{msg_id}/attempt/{attempt_id}/content/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}, {name: attempt_id, var: attempt_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, attempt_id: $attempt_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete message payload
#
# DELETE /api/v1/app/{app_id}/msg/{msg_id}/content/
# operationId: expunge_message_payload_api_v1_app__app_id__msg__msg_id__content__delete
export def "expunge-message-payload-api-v1-app-app-id-msg-msg-id-content-delete" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/app/{app_id}/msg/{msg_id}/content/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempted Destinations
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/endpoint/
# Returns: record<data: table<channels: list, createdAt: string, description: string, disabled: bool, filterTypes: list, id: string, metadata: record, nextAttempt: string, rateLimit: int, status: int, uid: string, url: string, version: int>, done: bool, iterator: string>
# operationId: list_attempted_destinations_api_v1_app__app_id__msg__msg_id__endpoint__get
export def "list-attempted-destinations-api-v1-app-app-id-msg-msg-id-endpoint-get" [
  app_id: string
  msg_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. msgep_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/{msg_id}/endpoint/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, iterator: $iterator, limit: $limit, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Attempts For Endpoint
#
# GET /api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/attempt/
# DEPRECATED
# Returns: record<data: table<endpointId: string, id: string, msgId: string, response: string, responseStatusCode: int, status: int, timestamp: string, triggerType: int, url: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_attempts_for_endpoint_api_v1_app__app_id__msg__msg_id__endpoint__endpoint_id__attempt__get
@deprecated
export def "list-attempts-for-endpoint-api-v1-app-app-id-msg-msg-id-endpoint-endpoint-id-attempt-get" [
  app_id: string
  msg_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. atmpt_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --event-types: list<string> # nullable
  --channel: string # nullable, e.g. project_1337
  --status: int@status-completer
  --before: string # nullable, format: date-time
  --after: string # nullable, format: date-time
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/attempt/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}, {name: endpoint_id, var: endpoint_id}]
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: event_types, var: event_types, style: multi}, {name: channel, var: channel}, {name: status, var: status}, {name: before, var: before}, {name: after, var: after}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, endpoint_id: $endpoint_id, iterator: $iterator, limit: $limit, event_types: $event_types, channel: $channel, status: $status, before: $before, after: $after, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Resend Webhook
#
# POST /api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/resend/
# operationId: resend_webhook_api_v1_app__app_id__msg__msg_id__endpoint__endpoint_id__resend__post
export def "resend-webhook-api-v1-app-app-id-msg-msg-id-endpoint-endpoint-id-resend-post" [
  app_id: string
  msg_id: string
  endpoint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/app/{app_id}/msg/{msg_id}/endpoint/{endpoint_id}/resend/"
    path_params: [{name: app_id, var: app_id}, {name: msg_id, var: msg_id}, {name: endpoint_id, var: endpoint_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    app_id: $app_id, msg_id: $msg_id, endpoint_id: $endpoint_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Consumer App Portal Access
#
# POST /api/v1/auth/app-portal-access/{app_id}/
# Returns: record<token: string, url: string>
# operationId: get_app_portal_access_api_v1_auth_app_portal_access__app_id___post
export def "get-app-portal-access-api-v1-auth-app-portal-access-app-id-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --feature-flags: list<string> # default: [], e.g. []
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/auth/app-portal-access/{app_id}/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: featureFlags, var: feature_flags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key, feature_flags: $feature_flags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Expire All
#
# POST /api/v1/auth/app/{app_id}/expire-all/
# operationId: expire_all_api_v1_auth_app__app_id__expire_all__post
export def "expire-all-api-v1-auth-app-app-id-expire-all-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --expiry: int # How many seconds until the old key is expired. (nullable, e.g. 60)
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/v1/auth/app/{app_id}/expire-all/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: expiry, var: expiry}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key, expiry: $expiry
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Dashboard Access
#
# POST /api/v1/auth/dashboard-access/{app_id}/
# DEPRECATED
# Returns: record<token: string, url: string>
# operationId: get_dashboard_access_api_v1_auth_dashboard_access__app_id___post
@deprecated
export def "get-dashboard-access-api-v1-auth-dashboard-access-app-id-post" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/v1/auth/dashboard-access/{app_id}/"
    path_params: [{name: app_id, var: app_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Logout
#
# POST /api/v1/auth/logout/
# operationId: logout_api_v1_auth_logout__post
export def "logout-api-v1-auth-logout-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/v1/auth/logout/"
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Background Tasks
#
# GET /api/v1/background-task/
# Returns: record<data: table<data: record, id: string, status: string, task: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_background_tasks_api_v1_background_task__get
export def "list-background-tasks-api-v1-background-task-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. qtask_1srOrx2ZWZBpBUvZwXKQmoEYga2
  --limit: int # default: 50
  --order: string@order-completer # default: descending
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/background-task/"
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: order, var: order}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    iterator: $iterator, limit: $limit, order: $order, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Background Task
#
# GET /api/v1/background-task/{task_id}/
# Returns: record<data: record, id: string, status: string, task: string>
# operationId: get_background_task_api_v1_background_task__task_id___get
export def "get-background-task-api-v1-background-task-task-id-get" [
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
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/background-task/{task_id}/"
    path_params: [{name: task_id, var: task_id}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_id: $task_id, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List Event Types
#
# GET /api/v1/event-type/
# Returns: record<data: table<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>, done: bool, iterator: string, prevIterator: string>
# operationId: list_event_types_api_v1_event_type__get
export def "list-event-types-api-v1-event-type-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --iterator: string # nullable, e.g. user.signup
  --limit: int # default: 50
  --with-content: oneof<nothing, bool> # default: false
  --include-archived: oneof<nothing, bool> # default: false
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/event-type/"
    query: [{name: iterator, var: iterator}, {name: limit, var: limit}, {name: with_content, var: with_content}, {name: include_archived, var: include_archived}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    iterator: $iterator, limit: $limit, with_content: $with_content, include_archived: $include_archived, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Event Type
#
# POST /api/v1/event-type/
# Returns: record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>
# operationId: create_event_type_api_v1_event_type__post
export def "create-event-type-api-v1-event-type-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --archived: oneof<nothing, bool> # default: false, e.g. false
  description: string # e.g. A user has signed up
  --feature-flag: string # nullable, e.g. cool-new-feature
  name: string # e.g. user.signup
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/v1/event-type/"
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: description, var: description}, {name: featureFlag, var: feature_flag}, {name: name, var: name}, {name: schemas, var: schemas}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    idempotency_key: $idempotency_key, archived: $archived, description: $description, feature_flag: $feature_flag, name: $name, schemas: $schemas
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive Event Type
#
# DELETE /api/v1/event-type/{event_type_name}/
# operationId: delete_event_type_api_v1_event_type__event_type_name___delete
export def "delete-event-type-api-v1-event-type-event-type-name-delete" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expunge: oneof<nothing, bool> # default: false
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/v1/event-type/{event_type_name}/"
    path_params: [{name: event_type_name, var: event_type_name}]
    query: [{name: expunge, var: expunge}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    event_type_name: $event_type_name, expunge: $expunge, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Event Type
#
# GET /api/v1/event-type/{event_type_name}/
# Returns: record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>
# operationId: get_event_type_api_v1_event_type__event_type_name___get
export def "get-event-type-api-v1-event-type-event-type-name-get" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/v1/event-type/{event_type_name}/"
    path_params: [{name: event_type_name, var: event_type_name}]
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event_type_name: $event_type_name, idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Event Type
#
# PUT /api/v1/event-type/{event_type_name}/
# Returns: record<archived: bool, createdAt: string, description: string, featureFlag: string, name: string, schemas: record, updatedAt: string>
# operationId: update_event_type_api_v1_event_type__event_type_name___put
export def "update-event-type-api-v1-event-type-event-type-name-put" [
  event_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
  --archived: oneof<nothing, bool> # default: false, e.g. false
  description: string # e.g. A user has signed up
  --feature-flag: string # nullable, e.g. cool-new-feature
  --schemas: record # The schema for the event type for a specific version as a JSON schema. (nullable, e.g. {1: {description: An invoice was paid by a user, properties: {invoiceId: {description: The invoice id, type: string}, userId: {description: The user id, type: string}}, required: [invoiceId, userId], title: Invoice Paid Event, type: object}})
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/api/v1/event-type/{event_type_name}/"
    path_params: [{name: event_type_name, var: event_type_name}]
    header: [{name: idempotency-key, var: idempotency_key}]
    body: {content_type: "application/json", kind: json, fields: [{name: archived, var: archived}, {name: description, var: description}, {name: featureFlag, var: feature_flag}, {name: schemas, var: schemas}]}
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    event_type_name: $event_type_name, idempotency_key: $idempotency_key, archived: $archived, description: $description, feature_flag: $feature_flag, schemas: $schemas
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Health
#
# GET /api/v1/health/
# operationId: health_api_v1_health__get
export def "health-api-v1-health-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --idempotency-key: string # The request's idempotency key (nullable)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/v1/health/"
    header: [{name: idempotency-key, var: idempotency_key}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    idempotency_key: $idempotency_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
