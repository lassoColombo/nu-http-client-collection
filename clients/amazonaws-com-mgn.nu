# Auto-generated client for Application Migration Service v2020-02-26
# Source: https://api.apis.guru/v2/specs/amazonaws.com/mgn/2020-02-26/openapi.json
# Auth: --token flag or $env.APPLICATION_MIGRATION_SERVICE_TOKEN

const CLIENT = {
  base_url: "http://mgn.us-east-1.amazonaws.com"
  token_env_var: "APPLICATION_MIGRATION_SERVICE_TOKEN"
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

def base-url-completer [] { ["http://mgn.us-east-1.amazonaws.com" "http://mgn.us-east-2.amazonaws.com" "http://mgn.us-west-1.amazonaws.com" "http://mgn.us-west-2.amazonaws.com" "http://mgn.us-gov-west-1.amazonaws.com" "http://mgn.us-gov-east-1.amazonaws.com" "http://mgn.ca-central-1.amazonaws.com" "http://mgn.eu-north-1.amazonaws.com" "http://mgn.eu-west-1.amazonaws.com" "http://mgn.eu-west-2.amazonaws.com" "http://mgn.eu-west-3.amazonaws.com" "http://mgn.eu-central-1.amazonaws.com" "http://mgn.eu-south-1.amazonaws.com" "http://mgn.af-south-1.amazonaws.com" "http://mgn.ap-northeast-1.amazonaws.com" "http://mgn.ap-northeast-2.amazonaws.com" "http://mgn.ap-northeast-3.amazonaws.com" "http://mgn.ap-southeast-1.amazonaws.com" "http://mgn.ap-southeast-2.amazonaws.com" "http://mgn.ap-east-1.amazonaws.com" "http://mgn.ap-south-1.amazonaws.com" "http://mgn.sa-east-1.amazonaws.com" "http://mgn.me-south-1.amazonaws.com" "https://mgn.us-east-1.amazonaws.com" "https://mgn.us-east-2.amazonaws.com" "https://mgn.us-west-1.amazonaws.com" "https://mgn.us-west-2.amazonaws.com" "https://mgn.us-gov-west-1.amazonaws.com" "https://mgn.us-gov-east-1.amazonaws.com" "https://mgn.ca-central-1.amazonaws.com" "https://mgn.eu-north-1.amazonaws.com" "https://mgn.eu-west-1.amazonaws.com" "https://mgn.eu-west-2.amazonaws.com" "https://mgn.eu-west-3.amazonaws.com" "https://mgn.eu-central-1.amazonaws.com" "https://mgn.eu-south-1.amazonaws.com" "https://mgn.af-south-1.amazonaws.com" "https://mgn.ap-northeast-1.amazonaws.com" "https://mgn.ap-northeast-2.amazonaws.com" "https://mgn.ap-northeast-3.amazonaws.com" "https://mgn.ap-southeast-1.amazonaws.com" "https://mgn.ap-southeast-2.amazonaws.com" "https://mgn.ap-east-1.amazonaws.com" "https://mgn.ap-south-1.amazonaws.com" "https://mgn.sa-east-1.amazonaws.com" "https://mgn.me-south-1.amazonaws.com" "http://mgn.cn-north-1.amazonaws.com.cn" "http://mgn.cn-northwest-1.amazonaws.com.cn" "https://mgn.cn-north-1.amazonaws.com.cn" "https://mgn.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def boot-mode-completer [] { ["LEGACY_BIOS" "UEFI"] }
def launch-disposition-completer [] { ["STARTED" "STOPPED"] }
def target-instance-type-right-sizing-method-completer [] { ["BASIC" "NONE"] }
def data-plane-routing-completer [] { ["PRIVATE_IP" "PUBLIC_IP"] }
def default-large-staging-disk-type-completer [] { ["GP2" "GP3" "ST1"] }
def ebs-encryption-completer [] { ["CUSTOM" "DEFAULT"] }
def category-completer [] { ["BACKUP" "CONFIGURATION" "DISASTER_RECOVERY" "LICENSE_AND_SUBSCRIPTION" "NETWORKING" "OBSERVABILITY" "OPERATING_SYSTEM" "OTHER" "SECURITY" "VALIDATION"] }
def replication-type-completer [] { ["AGENT_BASED" "SNAPSHOT_SHIPPING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    archive-application: "record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>"
    archive-wave: "record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>"
    associate-applications: "record"
    associate-source-servers: "record"
    change-server-life-cycle-state: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    create-application: "record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>"
    create-launch-configuration-template: "record<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record<iops: int, throughput: int, volumeType: string>, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, smallVolumeConf: record<iops: int, throughput: int, volumeType: string>, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>"
    create-replication-configuration-template: "record<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>"
    create-wave: "record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>"
    delete-application: "record"
    delete-job: "record"
    delete-launch-configuration-template: "record"
    delete-replication-configuration-template: "record"
    delete-source-server: "record"
    delete-wave: "record"
    describe-job-log-items: "record<items: table<event: string, eventData: record, logDateTime: string>, nextToken: string>"
    describe-jobs: "record<items: table<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list, status: string, tags: record, type: string>, nextToken: string>"
    describe-launch-configuration-templates: "record<items: table<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record, mapAutoTaggingMpeID: string, postLaunchActions: record, smallVolumeConf: record, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>, nextToken: string>"
    describe-replication-configuration-templates: "record<items: table<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>, nextToken: string>"
    describe-source-servers: "record<items: table<applicationID: string, arn: string, dataReplicationInfo: record, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record, lifeCycle: record, replicationType: string, sourceProperties: record, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>, nextToken: string>"
    describe-vcenter-clients: "record<items: table<arn: string, datacenterName: string, hostname: string, lastSeenDatetime: string, sourceServerTags: record, tags: record, vcenterClientID: string, vcenterUUID: string>, nextToken: string>"
    disassociate-applications: "record"
    disassociate-source-servers: "record"
    disconnect-from-service: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    finalize-cutover: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    get-launch-configuration: "record<bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, name: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, sourceServerID: string, targetInstanceTypeRightSizingMethod: string>"
    get-replication-configuration: "record<associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, name: string, replicatedDisks: table<deviceName: string, iops: int, isBootDisk: bool, stagingDiskType: string, throughput: int>, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, sourceServerID: string, stagingAreaSubnetId: string, stagingAreaTags: record, useDedicatedReplicationServer: bool>"
    initialize-service: "record"
    list-applications: "record<items: table<applicationAggregatedStatus: record, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>, nextToken: string>"
    list-export-errors: "record<items: table<errorData: record, errorDateTime: string>, nextToken: string>"
    list-exports: "record<items: table<creationDateTime: string, endDateTime: string, exportID: string, progressPercentage: float, s3Bucket: string, s3BucketOwner: string, s3Key: string, status: string, summary: record>, nextToken: string>"
    list-import-errors: "record<items: table<errorData: record, errorDateTime: string, errorType: string>, nextToken: string>"
    list-imports: "record<items: table<creationDateTime: string, endDateTime: string, importID: string, progressPercentage: float, s3BucketSource: record, status: string, summary: record>, nextToken: string>"
    list-source-server-actions: "record<items: table<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, order: int, parameters: record, timeoutSeconds: int>, nextToken: string>"
    list-tags-for-resource: "record<tags: record>"
    list-template-actions: "record<items: table<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, operatingSystem: string, order: int, parameters: record, timeoutSeconds: int>, nextToken: string>"
    list-waves: "record<items: table<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record, waveID: string>, nextToken: string>"
    mark-as-archived: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    put-source-server-action: "record<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, order: int, parameters: record, timeoutSeconds: int>"
    put-template-action: "record<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, operatingSystem: string, order: int, parameters: record, timeoutSeconds: int>"
    remove-source-server-action: "record"
    remove-template-action: "record"
    retry-data-replication: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    start-cutover: "record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>"
    start-export: "record<exportTask: record<creationDateTime: string, endDateTime: string, exportID: string, progressPercentage: float, s3Bucket: string, s3BucketOwner: string, s3Key: string, status: string, summary: record<applicationsCount: int, serversCount: int, wavesCount: int>>>"
    start-import: "record<importTask: record<creationDateTime: string, endDateTime: string, importID: string, progressPercentage: float, s3BucketSource: record<s3Bucket: string, s3BucketOwner: string, s3Key: string>, status: string, summary: record<applications: record, servers: record, waves: record>>>"
    start-replication: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    start-test: "record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>"
    terminate-target-instances: "record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>"
    unarchive-application: "record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>"
    unarchive-wave: "record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>"
    update-application: "record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>"
    update-launch-configuration: "record<bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, name: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, sourceServerID: string, targetInstanceTypeRightSizingMethod: string>"
    update-launch-configuration-template: "record<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record<iops: int, throughput: int, volumeType: string>, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, smallVolumeConf: record<iops: int, throughput: int, volumeType: string>, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>"
    update-replication-configuration: "record<associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, name: string, replicatedDisks: table<deviceName: string, iops: int, isBootDisk: bool, stagingDiskType: string, throughput: int>, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, sourceServerID: string, stagingAreaSubnetId: string, stagingAreaTags: record, useDedicatedReplicationServer: bool>"
    update-replication-configuration-template: "record<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>"
    update-source-server-replication-type: "record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>"
    update-wave: "record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["archive-application" "archive-wave" "associate-applications" "associate-source-servers" "change-server-life-cycle-state" "create-application" "create-launch-configuration-template" "create-replication-configuration-template" "create-wave" "delete-application" "delete-job" "delete-launch-configuration-template" "delete-replication-configuration-template" "delete-source-server" "delete-vcenter-client" "delete-wave" "describe-job-log-items" "describe-jobs" "describe-launch-configuration-templates" "describe-replication-configuration-templates" "describe-source-servers" "describe-vcenter-clients" "disassociate-applications" "disassociate-source-servers" "disconnect-from-service" "finalize-cutover" "get-launch-configuration" "get-replication-configuration" "initialize-service" "list-applications" "list-export-errors" "list-exports" "list-import-errors" "list-imports" "list-source-server-actions" "list-tags-for-resource" "tag-resource" "list-template-actions" "list-waves" "mark-as-archived" "put-source-server-action" "put-template-action" "remove-source-server-action" "remove-template-action" "retry-data-replication" "start-cutover" "start-export" "start-import" "start-replication" "start-test" "terminate-target-instances" "unarchive-application" "unarchive-wave" "untag-resource" "update-application" "update-launch-configuration" "update-launch-configuration-template" "update-replication-configuration" "update-replication-configuration-template" "update-source-server-replication-type" "update-wave" "commands"] | sort) } | get name | first)
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

# Archive application.
#
# POST /ArchiveApplication
# Returns: record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>
# operationId: ArchiveApplication
export def "archive-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ArchiveApplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive wave.
#
# POST /ArchiveWave
# Returns: record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>
# operationId: ArchiveWave
export def "archive-wave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ArchiveWave"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate applications to wave.
#
# POST /AssociateApplications
# Returns: record
# operationId: AssociateApplications
export def "associate-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_i_ds: list<string> # Application IDs list.
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/AssociateApplications"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationIDs, var: application_i_ds}, {name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_i_ds: $application_i_ds, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Associate source servers to application.
#
# POST /AssociateSourceServers
# Returns: record
# operationId: AssociateSourceServers
export def "associate-source-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  source_server_i_ds: list<string> # Source server IDs list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/AssociateSourceServers"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}, {name: sourceServerIDs, var: source_server_i_ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id, source_server_i_ds: $source_server_i_ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the user to set the SourceServer.LifeCycle.state property for specific Source Server IDs to one of the following: READY_FOR_TEST or READY_FOR_CUTOVER. This command only works if the Source Server is already launchable (dataReplicationInfo.lagDuration is not null.)
#
# POST /ChangeServerLifeCycleState
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: ChangeServerLifeCycleState
export def "change-server-life-cycle-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  life_cycle: record # The request to change the source server migration lifecycle state. — shape: {state?: "READY_FOR_TEST"|"READY_FOR_CUTOVER"|"CUTOVER"}
  source_server_id: string # The request to change the source server migration lifecycle state by source server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ChangeServerLifeCycleState"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: lifeCycle, var: life_cycle}, {name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, life_cycle: $life_cycle, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create application.
#
# POST /CreateApplication
# Returns: record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>
# operationId: CreateApplication
export def "create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Application description.
  name: string # Application name.
  --tags: record # Application tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreateApplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Launch Configuration Template.
#
# POST /CreateLaunchConfigurationTemplate
# Returns: record<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record<iops: int, throughput: int, volumeType: string>, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, smallVolumeConf: record<iops: int, throughput: int, volumeType: string>, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>
# operationId: CreateLaunchConfigurationTemplate
export def "create-launch-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-public-ip-address: oneof<nothing, bool> # Associate public Ip address.
  --boot-mode: string@boot-mode-completer # Launch configuration template boot mode.
  --copy-private-ip: oneof<nothing, bool> # Copy private Ip.
  --copy-tags: oneof<nothing, bool> # Copy tags.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --large-volume-conf: record # Launch template disk configuration. — shape: {iops?: int, throughput?: int, volumeType?: "io1"|"io2"|"gp3"|"gp2"|"st1"|"sc1"|"standard"}
  --launch-disposition: string@launch-disposition-completer # Launch disposition.
  --licensing: record # Configure Licensing. — shape: {osByol?: bool}
  --map-auto-tagging-mpe-id: string # Launch configuration template map auto tagging MPE ID.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: string, deployment?: "TEST_AND_CUTOVER"|"CUTOVER_ONLY"|"TEST_ONLY", s3LogBucket?: string, s3OutputKeyPrefix?: string, ssmDocuments?: list}
  --small-volume-conf: record # Launch template disk configuration. — shape: {iops?: int, throughput?: int, volumeType?: "io1"|"io2"|"gp3"|"gp2"|"st1"|"sc1"|"standard"}
  --small-volume-max-size: int # Small volume maximum size.
  --tags: record # Request to associate tags during creation of a Launch Configuration Template.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Target instance type right-sizing method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreateLaunchConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: associatePublicIpAddress, var: associate_public_ip_address}, {name: bootMode, var: boot_mode}, {name: copyPrivateIp, var: copy_private_ip}, {name: copyTags, var: copy_tags}, {name: enableMapAutoTagging, var: enable_map_auto_tagging}, {name: largeVolumeConf, var: large_volume_conf}, {name: launchDisposition, var: launch_disposition}, {name: licensing, var: licensing}, {name: mapAutoTaggingMpeID, var: map_auto_tagging_mpe_id}, {name: postLaunchActions, var: post_launch_actions}, {name: smallVolumeConf, var: small_volume_conf}, {name: smallVolumeMaxSize, var: small_volume_max_size}, {name: tags, var: tags}, {name: targetInstanceTypeRightSizingMethod, var: target_instance_type_right_sizing_method}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, associate_public_ip_address: $associate_public_ip_address, boot_mode: $boot_mode, copy_private_ip: $copy_private_ip, copy_tags: $copy_tags, enable_map_auto_tagging: $enable_map_auto_tagging, large_volume_conf: $large_volume_conf, launch_disposition: $launch_disposition, licensing: $licensing, map_auto_tagging_mpe_id: $map_auto_tagging_mpe_id, post_launch_actions: $post_launch_actions, small_volume_conf: $small_volume_conf, small_volume_max_size: $small_volume_max_size, tags: $tags, target_instance_type_right_sizing_method: $target_instance_type_right_sizing_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new ReplicationConfigurationTemplate.
#
# POST /CreateReplicationConfigurationTemplate
# Returns: record<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>
# operationId: CreateReplicationConfigurationTemplate
export def "create-replication-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-default-security-group: oneof<nothing, bool> # Request to associate the default Application Migration Service Security group with the Replication Settings template.
  bandwidth_throttling: int # Request to configure bandwidth throttling during Replication Settings template creation.
  --create-public-ip: oneof<nothing, bool> # Request to create Public IP during Replication Settings template creation.
  data_plane_routing: string@data-plane-routing-completer # Request to configure data plane routing during Replication Settings template creation.
  default_large_staging_disk_type: string@default-large-staging-disk-type-completer # Request to configure the default large staging disk EBS volume type during Replication Settings template creation.
  ebs_encryption: string@ebs-encryption-completer # Request to configure EBS encryption during Replication Settings template creation.
  --ebs-encryption-key-arn: string # Request to configure an EBS encryption key during Replication Settings template creation.
  replication_server_instance_type: string # Request to configure the Replication Server instance type during Replication Settings template creation.
  replication_servers_security_groups_i_ds: list<string> # Request to configure the Replication Server Security group ID during Replication Settings template creation.
  staging_area_subnet_id: string # Request to configure the Staging Area subnet ID during Replication Settings template creation.
  staging_area_tags: record # Request to configure Staging Area tags during Replication Settings template creation.
  --tags: record # Request to configure tags during Replication Settings template creation.
  --use-dedicated-replication-server: oneof<nothing, bool> # Request to use Dedicated Replication Servers during Replication Settings template creation.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreateReplicationConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: associateDefaultSecurityGroup, var: associate_default_security_group, required: true}, {name: bandwidthThrottling, var: bandwidth_throttling}, {name: createPublicIP, var: create_public_ip, required: true}, {name: dataPlaneRouting, var: data_plane_routing}, {name: defaultLargeStagingDiskType, var: default_large_staging_disk_type}, {name: ebsEncryption, var: ebs_encryption}, {name: ebsEncryptionKeyArn, var: ebs_encryption_key_arn}, {name: replicationServerInstanceType, var: replication_server_instance_type}, {name: replicationServersSecurityGroupsIDs, var: replication_servers_security_groups_i_ds}, {name: stagingAreaSubnetId, var: staging_area_subnet_id}, {name: stagingAreaTags, var: staging_area_tags}, {name: tags, var: tags}, {name: useDedicatedReplicationServer, var: use_dedicated_replication_server, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, associate_default_security_group: $associate_default_security_group, bandwidth_throttling: $bandwidth_throttling, create_public_ip: $create_public_ip, data_plane_routing: $data_plane_routing, default_large_staging_disk_type: $default_large_staging_disk_type, ebs_encryption: $ebs_encryption, ebs_encryption_key_arn: $ebs_encryption_key_arn, replication_server_instance_type: $replication_server_instance_type, replication_servers_security_groups_i_ds: $replication_servers_security_groups_i_ds, staging_area_subnet_id: $staging_area_subnet_id, staging_area_tags: $staging_area_tags, tags: $tags, use_dedicated_replication_server: $use_dedicated_replication_server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create wave.
#
# POST /CreateWave
# Returns: record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>
# operationId: CreateWave
export def "create-wave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Wave description.
  name: string # Wave name.
  --tags: record # Wave tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/CreateWave"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, name: $name, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete application.
#
# POST /DeleteApplication
# Returns: record
# operationId: DeleteApplication
export def "delete-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteApplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single Job by ID.
#
# POST /DeleteJob
# Returns: record
# operationId: DeleteJob
export def "delete-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_id: string # Request to delete Job from service by Job ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteJob"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobID, var: job_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_id: $job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single Launch Configuration Template by ID.
#
# POST /DeleteLaunchConfigurationTemplate
# Returns: record
# operationId: DeleteLaunchConfigurationTemplate
export def "delete-launch-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  launch_configuration_template_id: string # ID of resource to be deleted.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteLaunchConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: launchConfigurationTemplateID, var: launch_configuration_template_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, launch_configuration_template_id: $launch_configuration_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single Replication Configuration Template by ID
#
# POST /DeleteReplicationConfigurationTemplate
# Returns: record
# operationId: DeleteReplicationConfigurationTemplate
export def "delete-replication-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  replication_configuration_template_id: string # Request to delete Replication Configuration Template from service by Replication Configuration Template ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteReplicationConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: replicationConfigurationTemplateID, var: replication_configuration_template_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, replication_configuration_template_id: $replication_configuration_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a single source server by ID.
#
# POST /DeleteSourceServer
# Returns: record
# operationId: DeleteSourceServer
export def "delete-source-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to delete Source Server from service by Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteSourceServer"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a given vCenter client by ID.
#
# POST /DeleteVcenterClient
# operationId: DeleteVcenterClient
export def "delete-vcenter-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  vcenter_client_id: string # ID of resource to be deleted.
]: any -> any {
  $in | http-request {
    method: post
    path: "/DeleteVcenterClient"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: vcenterClientID, var: vcenter_client_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, vcenter_client_id: $vcenter_client_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete wave.
#
# POST /DeleteWave
# Returns: record
# operationId: DeleteWave
export def "delete-wave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DeleteWave"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves detailed job log items with paging.
#
# POST /DescribeJobLogItems
# Returns: record<items: table<event: string, eventData: record, logDateTime: string>, nextToken: string>
# operationId: DescribeJobLogItems
export def "describe-job-log-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  job_id: string # Request to describe Job log job ID.
  --body-max-results: int # Request to describe Job log item maximum results. (spec name: maxResults)
  --body-next-token: string # Request to describe Job log next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DescribeJobLogItems"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: jobID, var: job_id}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, job_id: $job_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of Jobs. Use the JobsID and fromDate and toData filters to limit which jobs are returned. The response is sorted by creationDataTime - latest date first. Jobs are normally created by the StartTest, StartCutover, and TerminateTargetInstances APIs. Jobs are also created by DiagnosticLaunch and TerminateDiagnosticInstances, which are APIs available only to *Support* and only used in response to relevant support tickets.
#
# POST /DescribeJobs
# Returns: record<items: table<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list, status: string, tags: record, type: string>, nextToken: string>
# operationId: DescribeJobs
export def "describe-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Request to describe Job log filters. — shape: {fromDate?: string, jobIDs?: list<string>, toDate?: string}
  --body-max-results: int # Request to describe job log items by max results. (spec name: maxResults)
  --body-next-token: string # Request to describe job log items by next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DescribeJobs"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all Launch Configuration Templates, filtered by Launch Configuration Template IDs
#
# POST /DescribeLaunchConfigurationTemplates
# Returns: record<items: table<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record, mapAutoTaggingMpeID: string, postLaunchActions: record, smallVolumeConf: record, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>, nextToken: string>
# operationId: DescribeLaunchConfigurationTemplates
export def "describe-launch-configuration-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --launch-configuration-template-i-ds: list<string> # Request to filter Launch Configuration Templates list by Launch Configuration Template ID.
  --body-max-results: int # Maximum results to be returned in DescribeLaunchConfigurationTemplates. (spec name: maxResults)
  --body-next-token: string # Next pagination token returned from DescribeLaunchConfigurationTemplates. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DescribeLaunchConfigurationTemplates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: launchConfigurationTemplateIDs, var: launch_configuration_template_i_ds}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, launch_configuration_template_i_ds: $launch_configuration_template_i_ds, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all ReplicationConfigurationTemplates, filtered by Source Server IDs.
#
# POST /DescribeReplicationConfigurationTemplates
# Returns: record<items: table<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>, nextToken: string>
# operationId: DescribeReplicationConfigurationTemplates
export def "describe-replication-configuration-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body-max-results: int # Request to describe Replication Configuration template by max results. (spec name: maxResults)
  --body-next-token: string # Request to describe Replication Configuration template by next token. (spec name: nextToken)
  --replication-configuration-template-i-ds: list<string> # Request to describe Replication Configuration template by template IDs.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DescribeReplicationConfigurationTemplates"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: replicationConfigurationTemplateIDs, var: replication_configuration_template_i_ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, body_max_results: $body_max_results, body_next_token: $body_next_token, replication_configuration_template_i_ds: $replication_configuration_template_i_ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all SourceServers or multiple SourceServers by ID.
#
# POST /DescribeSourceServers
# Returns: record<items: table<applicationID: string, arn: string, dataReplicationInfo: record, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record, lifeCycle: record, replicationType: string, sourceProperties: record, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>, nextToken: string>
# operationId: DescribeSourceServers
export def "describe-source-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Request to filter Source Servers list. — shape: {applicationIDs?: list<string>, isArchived?: bool, lifeCycleStates?: list<string>, replicationTypes?: list<string>, sourceServerIDs?: list<string>}
  --body-max-results: int # Request to filter Source Servers list by maximum results. (spec name: maxResults)
  --body-next-token: string # Request to filter Source Servers list by next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DescribeSourceServers"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of the installed vCenter clients.
#
# GET /DescribeVcenterClients
# Returns: record<items: table<arn: string, datacenterName: string, hostname: string, lastSeenDatetime: string, sourceServerTags: record, tags: record, vcenterClientID: string, vcenterUUID: string>, nextToken: string>
# operationId: DescribeVcenterClients
export def "describe-vcenter-clients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # Maximum results to be returned in DescribeVcenterClients.
  --next-token: string # Next pagination token to be provided for DescribeVcenterClients.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/DescribeVcenterClients"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate applications from wave.
#
# POST /DisassociateApplications
# Returns: record
# operationId: DisassociateApplications
export def "disassociate-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_i_ds: list<string> # Application IDs list.
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DisassociateApplications"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationIDs, var: application_i_ds}, {name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_i_ds: $application_i_ds, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disassociate source servers from application.
#
# POST /DisassociateSourceServers
# Returns: record
# operationId: DisassociateSourceServers
export def "disassociate-source-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  source_server_i_ds: list<string> # Source server IDs list.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DisassociateSourceServers"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}, {name: sourceServerIDs, var: source_server_i_ds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id, source_server_i_ds: $source_server_i_ds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disconnects specific Source Servers from Application Migration Service. Data replication is stopped immediately. All AWS resources created by Application Migration Service for enabling the replication of these source servers will be terminated / deleted within 90 minutes. Launched Test or Cutover instances will NOT be terminated. If the agent on the source server has not been prevented from communicating with the Application Migration Service service, then it will receive a command to uninstall itself (within approximately 10 minutes). The following properties of the SourceServer will be changed immediately: dataReplicationInfo.dataReplicationState will be set to DISCONNECTED; The totalStorageBytes property for each of dataReplicationInfo.replicatedDisks will be set to zero; dataReplicationInfo.lagDuration and dataReplicationInfo.lagDuration will be nullified.
#
# POST /DisconnectFromService
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: DisconnectFromService
export def "disconnect-from-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to disconnect Source Server from service by Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/DisconnectFromService"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finalizes the cutover immediately for specific Source Servers. All AWS resources created by Application Migration Service for enabling the replication of these source servers will be terminated / deleted within 90 minutes. Launched Test or Cutover instances will NOT be terminated. The AWS Replication Agent will receive a command to uninstall itself (within 10 minutes). The following properties of the SourceServer will be changed immediately: dataReplicationInfo.dataReplicationState will be changed to DISCONNECTED; The SourceServer.lifeCycle.state will be changed to CUTOVER; The totalStorageBytes property fo each of dataReplicationInfo.replicatedDisks will be set to zero; dataReplicationInfo.lagDuration and dataReplicationInfo.lagDuration will be nullified.
#
# POST /FinalizeCutover
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: FinalizeCutover
export def "finalize-cutover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to finalize Cutover by Source Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/FinalizeCutover"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all LaunchConfigurations available, filtered by Source Server IDs.
#
# POST /GetLaunchConfiguration
# Returns: record<bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, name: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, sourceServerID: string, targetInstanceTypeRightSizingMethod: string>
# operationId: GetLaunchConfiguration
export def "get-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to get Launch Configuration information by Source Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/GetLaunchConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all ReplicationConfigurations, filtered by Source Server ID.
#
# POST /GetReplicationConfiguration
# Returns: record<associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, name: string, replicatedDisks: table<deviceName: string, iops: int, isBootDisk: bool, stagingDiskType: string, throughput: int>, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, sourceServerID: string, stagingAreaSubnetId: string, stagingAreaTags: record, useDedicatedReplicationServer: bool>
# operationId: GetReplicationConfiguration
export def "get-replication-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Request to get Replication Configuration by Source Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/GetReplicationConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initialize Application Migration Service.
#
# POST /InitializeService
# Returns: record
# operationId: InitializeService
export def "initialize-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/InitializeService"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all applications or multiple applications by ID.
#
# POST /ListApplications
# Returns: record<items: table<applicationAggregatedStatus: record, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>, nextToken: string>
# operationId: ListApplications
export def "list-applications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Applications list filters. — shape: {applicationIDs?: list<string>, isArchived?: bool, waveIDs?: list<string>}
  --body-max-results: int # Maximum results to return when listing applications. (spec name: maxResults)
  --body-next-token: string # Request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListApplications"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List export errors.
#
# POST /ListExportErrors
# Returns: record<items: table<errorData: record, errorDateTime: string>, nextToken: string>
# operationId: ListExportErrors
export def "list-export-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  export_id: string # List export errors request export id.
  --body-max-results: int # List export errors request max results. (spec name: maxResults)
  --body-next-token: string # List export errors request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListExportErrors"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: exportID, var: export_id}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, export_id: $export_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List exports.
#
# POST /ListExports
# Returns: record<items: table<creationDateTime: string, endDateTime: string, exportID: string, progressPercentage: float, s3Bucket: string, s3BucketOwner: string, s3Key: string, status: string, summary: record>, nextToken: string>
# operationId: ListExports
export def "list-exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # List exports request filters. — shape: {exportIDs?: list<string>}
  --body-max-results: int # List export request max results. (spec name: maxResults)
  --body-next-token: string # List export request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListExports"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List import errors.
#
# POST /ListImportErrors
# Returns: record<items: table<errorData: record, errorDateTime: string, errorType: string>, nextToken: string>
# operationId: ListImportErrors
export def "list-import-errors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  import_id: string # List import errors request import id.
  --body-max-results: int # List import errors request max results. (spec name: maxResults)
  --body-next-token: string # List import errors request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImportErrors"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: importID, var: import_id}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, import_id: $import_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List imports.
#
# POST /ListImports
# Returns: record<items: table<creationDateTime: string, endDateTime: string, importID: string, progressPercentage: float, s3BucketSource: record, status: string, summary: record>, nextToken: string>
# operationId: ListImports
export def "list-imports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # List imports request filters. — shape: {importIDs?: list<string>}
  --body-max-results: int # List imports request max results. (spec name: maxResults)
  --body-next-token: string # List imports request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListImports"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List source server post migration custom actions.
#
# POST /ListSourceServerActions
# Returns: record<items: table<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, order: int, parameters: record, timeoutSeconds: int>, nextToken: string>
# operationId: ListSourceServerActions
export def "list-source-server-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Source server post migration custom action filters. — shape: {actionIDs?: list<string>}
  --body-max-results: int # Maximum amount of items to return when listing source server post migration custom actions. (spec name: maxResults)
  --body-next-token: string # Next token to use when listing source server post migration custom actions. (spec name: nextToken)
  source_server_id: string # Source server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListSourceServerActions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}, {name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all tags for your Application Migration Service resources.
#
# GET /tags/{resourceArn}
# Returns: record<tags: record>
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds or overwrites only the specified tags for the specified Application Migration Service resource or resources. When you specify an existing tag key, the value is overwritten with the new value. Each resource can have a maximum of 50 tags. Each tag consists of a key and optional value.
#
# POST /tags/{resourceArn}
# operationId: TagResource
export def "tag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  tags: record # Tag resource by Tags.
]: any -> any {
  $in | http-request {
    method: post
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List template post migration custom actions.
#
# POST /ListTemplateActions
# Returns: record<items: table<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, operatingSystem: string, order: int, parameters: record, timeoutSeconds: int>, nextToken: string>
# operationId: ListTemplateActions
export def "list-template-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Template post migration custom action filters. — shape: {actionIDs?: list<string>}
  launch_configuration_template_id: string # Launch configuration template ID.
  --body-max-results: int # Maximum amount of items to return when listing template post migration custom actions. (spec name: maxResults)
  --body-next-token: string # Next token to use when listing template post migration custom actions. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListTemplateActions"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: launchConfigurationTemplateID, var: launch_configuration_template_id}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, launch_configuration_template_id: $launch_configuration_template_id, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves all waves or multiple waves by ID.
#
# POST /ListWaves
# Returns: record<items: table<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record, waveID: string>, nextToken: string>
# operationId: ListWaves
export def "list-waves" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --filters: record # Waves list filters. — shape: {isArchived?: bool, waveIDs?: list<string>}
  --body-max-results: int # Maximum results to return when listing waves. (spec name: maxResults)
  --body-next-token: string # Request next token. (spec name: nextToken)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/ListWaves"
    query: [{name: maxResults, var: max_results}, {name: nextToken, var: next_token}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: filters, var: filters}, {name: maxResults, var: body_max_results}, {name: nextToken, var: body_next_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max_results: $max_results, next_token: $next_token, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, filters: $filters, body_max_results: $body_max_results, body_next_token: $body_next_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archives specific Source Servers by setting the SourceServer.isArchived property to true for specified SourceServers by ID. This command only works for SourceServers with a lifecycle. state which equals DISCONNECTED or CUTOVER.
#
# POST /MarkAsArchived
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: MarkAsArchived
export def "mark-as-archived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Mark as archived by Source Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/MarkAsArchived"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put source server post migration custom action.
#
# POST /PutSourceServerAction
# Returns: record<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, order: int, parameters: record, timeoutSeconds: int>
# operationId: PutSourceServerAction
export def "put-source-server-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Source server post migration custom action ID.
  action_name: string # Source server post migration custom action name.
  --active: oneof<nothing, bool> # Source server post migration custom action active status.
  --category: string@category-completer # Source server post migration custom action category.
  --description: string # Source server post migration custom action description.
  document_identifier: string # Source server post migration custom action document identifier.
  --document-version: string # Source server post migration custom action document version.
  --external-parameters: record # Source server post migration custom action external parameters.
  --must-succeed-for-cutover: oneof<nothing, bool> # Source server post migration custom action must succeed for cutover.
  order: int # Source server post migration custom action order.
  --parameters: record # Source server post migration custom action parameters.
  source_server_id: string # Source server ID.
  --timeout-seconds: int # Source server post migration custom action timeout in seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/PutSourceServerAction"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionID, var: action_id}, {name: actionName, var: action_name}, {name: active, var: active}, {name: category, var: category}, {name: description, var: description}, {name: documentIdentifier, var: document_identifier}, {name: documentVersion, var: document_version}, {name: externalParameters, var: external_parameters}, {name: mustSucceedForCutover, var: must_succeed_for_cutover}, {name: order, var: order}, {name: parameters, var: parameters}, {name: sourceServerID, var: source_server_id}, {name: timeoutSeconds, var: timeout_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, action_id: $action_id, action_name: $action_name, active: $active, category: $category, description: $description, document_identifier: $document_identifier, document_version: $document_version, external_parameters: $external_parameters, must_succeed_for_cutover: $must_succeed_for_cutover, order: $order, parameters: $parameters, source_server_id: $source_server_id, timeout_seconds: $timeout_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Put template post migration custom action.
#
# POST /PutTemplateAction
# Returns: record<actionID: string, actionName: string, active: bool, category: string, description: string, documentIdentifier: string, documentVersion: string, externalParameters: record, mustSucceedForCutover: bool, operatingSystem: string, order: int, parameters: record, timeoutSeconds: int>
# operationId: PutTemplateAction
export def "put-template-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Template post migration custom action ID.
  action_name: string # Template post migration custom action name.
  --active: oneof<nothing, bool> # Template post migration custom action active status.
  --category: string@category-completer # Template post migration custom action category.
  --description: string # Template post migration custom action description.
  document_identifier: string # Template post migration custom action document identifier.
  --document-version: string # Template post migration custom action document version.
  --external-parameters: record # Template post migration custom action external parameters.
  launch_configuration_template_id: string # Launch configuration template ID.
  --must-succeed-for-cutover: oneof<nothing, bool> # Template post migration custom action must succeed for cutover.
  --operating-system: string # Operating system eligible for this template post migration custom action.
  order: int # Template post migration custom action order.
  --parameters: record # Template post migration custom action parameters.
  --timeout-seconds: int # Template post migration custom action timeout in seconds.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/PutTemplateAction"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionID, var: action_id}, {name: actionName, var: action_name}, {name: active, var: active}, {name: category, var: category}, {name: description, var: description}, {name: documentIdentifier, var: document_identifier}, {name: documentVersion, var: document_version}, {name: externalParameters, var: external_parameters}, {name: launchConfigurationTemplateID, var: launch_configuration_template_id}, {name: mustSucceedForCutover, var: must_succeed_for_cutover}, {name: operatingSystem, var: operating_system}, {name: order, var: order}, {name: parameters, var: parameters}, {name: timeoutSeconds, var: timeout_seconds}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, action_id: $action_id, action_name: $action_name, active: $active, category: $category, description: $description, document_identifier: $document_identifier, document_version: $document_version, external_parameters: $external_parameters, launch_configuration_template_id: $launch_configuration_template_id, must_succeed_for_cutover: $must_succeed_for_cutover, operating_system: $operating_system, order: $order, parameters: $parameters, timeout_seconds: $timeout_seconds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove source server post migration custom action.
#
# POST /RemoveSourceServerAction
# Returns: record
# operationId: RemoveSourceServerAction
export def "remove-source-server-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Source server post migration custom action ID to remove.
  source_server_id: string # Source server ID of the post migration custom action to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RemoveSourceServerAction"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionID, var: action_id}, {name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, action_id: $action_id, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove template post migration custom action.
#
# POST /RemoveTemplateAction
# Returns: record
# operationId: RemoveTemplateAction
export def "remove-template-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  action_id: string # Template post migration custom action ID to remove.
  launch_configuration_template_id: string # Launch configuration template ID of the post migration custom action to remove.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RemoveTemplateAction"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionID, var: action_id}, {name: launchConfigurationTemplateID, var: launch_configuration_template_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, action_id: $action_id, launch_configuration_template_id: $launch_configuration_template_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Causes the data replication initiation sequence to begin immediately upon next Handshake for specified SourceServer IDs, regardless of when the previous initiation started. This command will not work if the SourceServer is not stalled or is in a DISCONNECTED or STOPPED state.
#
# POST /RetryDataReplication
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: RetryDataReplication
export def "retry-data-replication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # Retry data replication for Source Server ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/RetryDataReplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launches a Cutover Instance for specific Source Servers. This command starts a LAUNCH job whose initiatedBy property is StartCutover and changes the SourceServer.lifeCycle.state property to CUTTING_OVER.
#
# POST /StartCutover
# Returns: record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>
# operationId: StartCutover
export def "start-cutover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Start Cutover by Source Server IDs.
  --tags: record # Start Cutover by Tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StartCutover"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerIDs, var: source_server_i_ds}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_i_ds: $source_server_i_ds, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start export.
#
# POST /StartExport
# Returns: record<exportTask: record<creationDateTime: string, endDateTime: string, exportID: string, progressPercentage: float, s3Bucket: string, s3BucketOwner: string, s3Key: string, status: string, summary: record<applicationsCount: int, serversCount: int, wavesCount: int>>>
# operationId: StartExport
export def "start-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  s3_bucket: string # Start export request s3 bucket.
  --s3-bucket-owner: string # Start export request s3 bucket owner.
  s3_key: string # Start export request s3key.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StartExport"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: s3Bucket, var: s3_bucket}, {name: s3BucketOwner, var: s3_bucket_owner}, {name: s3Key, var: s3_key}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, s3_bucket: $s3_bucket, s3_bucket_owner: $s3_bucket_owner, s3_key: $s3_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Start import.
#
# POST /StartImport
# Returns: record<importTask: record<creationDateTime: string, endDateTime: string, importID: string, progressPercentage: float, s3BucketSource: record<s3Bucket: string, s3BucketOwner: string, s3Key: string>, status: string, summary: record<applications: record, servers: record, waves: record>>>
# operationId: StartImport
export def "start-import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --client-token: string # Start import request client token.
  s3_bucket_source: record # S3 bucket source. — shape: {s3Bucket?: string, s3BucketOwner?: string, s3Key?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StartImport"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientToken, var: client_token}, {name: s3BucketSource, var: s3_bucket_source}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, client_token: $client_token, s3_bucket_source: $s3_bucket_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts replication for SNAPSHOT_SHIPPING agents.
#
# POST /StartReplication
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: StartReplication
export def "start-replication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_id: string # ID of source server on which to start replication.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StartReplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Launches a Test Instance for specific Source Servers. This command starts a LAUNCH job whose initiatedBy property is StartTest and changes the SourceServer.lifeCycle.state property to TESTING.
#
# POST /StartTest
# Returns: record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>
# operationId: StartTest
export def "start-test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Start Test for Source Server IDs.
  --tags: record # Start Test by Tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/StartTest"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerIDs, var: source_server_i_ds}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_i_ds: $source_server_i_ds, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Starts a job that terminates specific launched EC2 Test and Cutover instances. This command will not work for any Source Server with a lifecycle.state of TESTING, CUTTING_OVER, or CUTOVER.
#
# POST /TerminateTargetInstances
# Returns: record<job: record<arn: string, creationDateTime: string, endDateTime: string, initiatedBy: string, jobID: string, participatingServers: list<record>, status: string, tags: record, type: string>>
# operationId: TerminateTargetInstances
export def "terminate-target-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  source_server_i_ds: list<string> # Terminate Target instance by Source Server IDs.
  --tags: record # Terminate Target instance by Tags.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/TerminateTargetInstances"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: sourceServerIDs, var: source_server_i_ds}, {name: tags, var: tags}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, source_server_i_ds: $source_server_i_ds, tags: $tags
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive application.
#
# POST /UnarchiveApplication
# Returns: record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>
# operationId: UnarchiveApplication
export def "unarchive-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UnarchiveApplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive wave.
#
# POST /UnarchiveWave
# Returns: record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>
# operationId: UnarchiveWave
export def "unarchive-wave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UnarchiveWave"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the specified set of tags from the specified set of Application Migration Service resources.
#
# DELETE /tags/{resourceArn}
# operationId: UntagResource
export def "untag-resource" [
  resource_arn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-keys: list<string> # Untag resource by Keys. (required)
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  http-request {
    method: delete
    path: "/tags/{resourceArn}"
    path_params: [{name: resourceArn, var: resource_arn}]
    query: [{name: tagKeys, var: tag_keys, style: multi, required: true}]
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_arn: $resource_arn, tag_keys: $tag_keys, x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update application.
#
# POST /UpdateApplication
# Returns: record<applicationAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, totalSourceServers: int>, applicationID: string, arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveID: string>
# operationId: UpdateApplication
export def "update-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  application_id: string # Application ID.
  --description: string # Application description.
  --name: string # Application name.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateApplication"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: applicationID, var: application_id}, {name: description, var: description}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, application_id: $application_id, description: $description, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates multiple LaunchConfigurations by Source Server ID.
#
# POST /UpdateLaunchConfiguration
# Returns: record<bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, name: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, sourceServerID: string, targetInstanceTypeRightSizingMethod: string>
# operationId: UpdateLaunchConfiguration
export def "update-launch-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --boot-mode: string@boot-mode-completer # Update Launch configuration boot mode request.
  --copy-private-ip: oneof<nothing, bool> # Update Launch configuration copy Private IP request.
  --copy-tags: oneof<nothing, bool> # Update Launch configuration copy Tags request.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --launch-disposition: string@launch-disposition-completer # Update Launch configuration launch disposition request.
  --licensing: record # Configure Licensing. — shape: {osByol?: bool}
  --map-auto-tagging-mpe-id: string # Launch configuration map auto tagging MPE ID.
  --name: string # Update Launch configuration name request.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: string, deployment?: "TEST_AND_CUTOVER"|"CUTOVER_ONLY"|"TEST_ONLY", s3LogBucket?: string, s3OutputKeyPrefix?: string, ssmDocuments?: list}
  source_server_id: string # Update Launch configuration by Source Server ID request.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Update Launch configuration Target instance right sizing request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateLaunchConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: bootMode, var: boot_mode}, {name: copyPrivateIp, var: copy_private_ip}, {name: copyTags, var: copy_tags}, {name: enableMapAutoTagging, var: enable_map_auto_tagging}, {name: launchDisposition, var: launch_disposition}, {name: licensing, var: licensing}, {name: mapAutoTaggingMpeID, var: map_auto_tagging_mpe_id}, {name: name, var: name}, {name: postLaunchActions, var: post_launch_actions}, {name: sourceServerID, var: source_server_id}, {name: targetInstanceTypeRightSizingMethod, var: target_instance_type_right_sizing_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, boot_mode: $boot_mode, copy_private_ip: $copy_private_ip, copy_tags: $copy_tags, enable_map_auto_tagging: $enable_map_auto_tagging, launch_disposition: $launch_disposition, licensing: $licensing, map_auto_tagging_mpe_id: $map_auto_tagging_mpe_id, name: $name, post_launch_actions: $post_launch_actions, source_server_id: $source_server_id, target_instance_type_right_sizing_method: $target_instance_type_right_sizing_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing Launch Configuration Template by ID.
#
# POST /UpdateLaunchConfigurationTemplate
# Returns: record<arn: string, associatePublicIpAddress: bool, bootMode: string, copyPrivateIp: bool, copyTags: bool, ec2LaunchTemplateID: string, enableMapAutoTagging: bool, largeVolumeConf: record<iops: int, throughput: int, volumeType: string>, launchConfigurationTemplateID: string, launchDisposition: string, licensing: record<osByol: bool>, mapAutoTaggingMpeID: string, postLaunchActions: record<cloudWatchLogGroupName: string, deployment: string, s3LogBucket: string, s3OutputKeyPrefix: string, ssmDocuments: list<record>>, smallVolumeConf: record<iops: int, throughput: int, volumeType: string>, smallVolumeMaxSize: int, tags: record, targetInstanceTypeRightSizingMethod: string>
# operationId: UpdateLaunchConfigurationTemplate
export def "update-launch-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-public-ip-address: oneof<nothing, bool> # Associate public Ip address.
  --boot-mode: string@boot-mode-completer # Launch configuration template boot mode.
  --copy-private-ip: oneof<nothing, bool> # Copy private Ip.
  --copy-tags: oneof<nothing, bool> # Copy tags.
  --enable-map-auto-tagging: oneof<nothing, bool> # Enable map auto tagging.
  --large-volume-conf: record # Launch template disk configuration. — shape: {iops?: int, throughput?: int, volumeType?: "io1"|"io2"|"gp3"|"gp2"|"st1"|"sc1"|"standard"}
  launch_configuration_template_id: string # Launch Configuration Template ID.
  --launch-disposition: string@launch-disposition-completer # Launch disposition.
  --licensing: record # Configure Licensing. — shape: {osByol?: bool}
  --map-auto-tagging-mpe-id: string # Launch configuration template map auto tagging MPE ID.
  --post-launch-actions: record # Post Launch Actions to executed on the Test or Cutover instance. — shape: {cloudWatchLogGroupName?: string, deployment?: "TEST_AND_CUTOVER"|"CUTOVER_ONLY"|"TEST_ONLY", s3LogBucket?: string, s3OutputKeyPrefix?: string, ssmDocuments?: list}
  --small-volume-conf: record # Launch template disk configuration. — shape: {iops?: int, throughput?: int, volumeType?: "io1"|"io2"|"gp3"|"gp2"|"st1"|"sc1"|"standard"}
  --small-volume-max-size: int # Small volume maximum size.
  --target-instance-type-right-sizing-method: string@target-instance-type-right-sizing-method-completer # Target instance type right-sizing method.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateLaunchConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: associatePublicIpAddress, var: associate_public_ip_address}, {name: bootMode, var: boot_mode}, {name: copyPrivateIp, var: copy_private_ip}, {name: copyTags, var: copy_tags}, {name: enableMapAutoTagging, var: enable_map_auto_tagging}, {name: largeVolumeConf, var: large_volume_conf}, {name: launchConfigurationTemplateID, var: launch_configuration_template_id}, {name: launchDisposition, var: launch_disposition}, {name: licensing, var: licensing}, {name: mapAutoTaggingMpeID, var: map_auto_tagging_mpe_id}, {name: postLaunchActions, var: post_launch_actions}, {name: smallVolumeConf, var: small_volume_conf}, {name: smallVolumeMaxSize, var: small_volume_max_size}, {name: targetInstanceTypeRightSizingMethod, var: target_instance_type_right_sizing_method}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, associate_public_ip_address: $associate_public_ip_address, boot_mode: $boot_mode, copy_private_ip: $copy_private_ip, copy_tags: $copy_tags, enable_map_auto_tagging: $enable_map_auto_tagging, large_volume_conf: $large_volume_conf, launch_configuration_template_id: $launch_configuration_template_id, launch_disposition: $launch_disposition, licensing: $licensing, map_auto_tagging_mpe_id: $map_auto_tagging_mpe_id, post_launch_actions: $post_launch_actions, small_volume_conf: $small_volume_conf, small_volume_max_size: $small_volume_max_size, target_instance_type_right_sizing_method: $target_instance_type_right_sizing_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to update multiple ReplicationConfigurations by Source Server ID.
#
# POST /UpdateReplicationConfiguration
# Returns: record<associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, name: string, replicatedDisks: table<deviceName: string, iops: int, isBootDisk: bool, stagingDiskType: string, throughput: int>, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, sourceServerID: string, stagingAreaSubnetId: string, stagingAreaTags: record, useDedicatedReplicationServer: bool>
# operationId: UpdateReplicationConfiguration
export def "update-replication-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --associate-default-security-group: oneof<nothing, bool> # Update replication configuration associate default Application Migration Service Security group request.
  --bandwidth-throttling: int # Update replication configuration bandwidth throttling request.
  --create-public-ip: oneof<nothing, bool> # Update replication configuration create Public IP request.
  --data-plane-routing: string@data-plane-routing-completer # Update replication configuration data plane routing request.
  --default-large-staging-disk-type: string@default-large-staging-disk-type-completer # Update replication configuration use default large Staging Disk type request.
  --ebs-encryption: string@ebs-encryption-completer # Update replication configuration EBS encryption request.
  --ebs-encryption-key-arn: string # Update replication configuration EBS encryption key ARN request.
  --name: string # Update replication configuration name request.
  --replicated-disks: list # Update replication configuration replicated disks request. — item shape: {deviceName?: string, iops?: int, isBootDisk?: bool, stagingDiskType?: "AUTO"|"GP2"|"IO1"|"SC1"|"ST1"|"STANDARD"|"GP3"|"IO2", throughput?: int}
  --replication-server-instance-type: string # Update replication configuration Replication Server instance type request.
  --replication-servers-security-groups-i-ds: list<string> # Update replication configuration Replication Server Security Groups IDs request.
  source_server_id: string # Update replication configuration Source Server ID request.
  --staging-area-subnet-id: string # Update replication configuration Staging Area subnet request.
  --staging-area-tags: record # Update replication configuration Staging Area Tags request.
  --use-dedicated-replication-server: oneof<nothing, bool> # Update replication configuration use dedicated Replication Server request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateReplicationConfiguration"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: associateDefaultSecurityGroup, var: associate_default_security_group}, {name: bandwidthThrottling, var: bandwidth_throttling}, {name: createPublicIP, var: create_public_ip}, {name: dataPlaneRouting, var: data_plane_routing}, {name: defaultLargeStagingDiskType, var: default_large_staging_disk_type}, {name: ebsEncryption, var: ebs_encryption}, {name: ebsEncryptionKeyArn, var: ebs_encryption_key_arn}, {name: name, var: name}, {name: replicatedDisks, var: replicated_disks}, {name: replicationServerInstanceType, var: replication_server_instance_type}, {name: replicationServersSecurityGroupsIDs, var: replication_servers_security_groups_i_ds}, {name: sourceServerID, var: source_server_id}, {name: stagingAreaSubnetId, var: staging_area_subnet_id}, {name: stagingAreaTags, var: staging_area_tags}, {name: useDedicatedReplicationServer, var: use_dedicated_replication_server}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, associate_default_security_group: $associate_default_security_group, bandwidth_throttling: $bandwidth_throttling, create_public_ip: $create_public_ip, data_plane_routing: $data_plane_routing, default_large_staging_disk_type: $default_large_staging_disk_type, ebs_encryption: $ebs_encryption, ebs_encryption_key_arn: $ebs_encryption_key_arn, name: $name, replicated_disks: $replicated_disks, replication_server_instance_type: $replication_server_instance_type, replication_servers_security_groups_i_ds: $replication_servers_security_groups_i_ds, source_server_id: $source_server_id, staging_area_subnet_id: $staging_area_subnet_id, staging_area_tags: $staging_area_tags, use_dedicated_replication_server: $use_dedicated_replication_server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates multiple ReplicationConfigurationTemplates by ID.
#
# POST /UpdateReplicationConfigurationTemplate
# Returns: record<arn: string, associateDefaultSecurityGroup: bool, bandwidthThrottling: int, createPublicIP: bool, dataPlaneRouting: string, defaultLargeStagingDiskType: string, ebsEncryption: string, ebsEncryptionKeyArn: string, replicationConfigurationTemplateID: string, replicationServerInstanceType: string, replicationServersSecurityGroupsIDs: list<string>, stagingAreaSubnetId: string, stagingAreaTags: record, tags: record, useDedicatedReplicationServer: bool>
# operationId: UpdateReplicationConfigurationTemplate
export def "update-replication-configuration-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --arn: string # Update replication configuration template ARN request.
  --associate-default-security-group: oneof<nothing, bool> # Update replication configuration template associate default Application Migration Service Security group request.
  --bandwidth-throttling: int # Update replication configuration template bandwidth throttling request.
  --create-public-ip: oneof<nothing, bool> # Update replication configuration template create Public IP request.
  --data-plane-routing: string@data-plane-routing-completer # Update replication configuration template data plane routing request.
  --default-large-staging-disk-type: string@default-large-staging-disk-type-completer # Update replication configuration template use default large Staging Disk type request.
  --ebs-encryption: string@ebs-encryption-completer # Update replication configuration template EBS encryption request.
  --ebs-encryption-key-arn: string # Update replication configuration template EBS encryption key ARN request.
  replication_configuration_template_id: string # Update replication configuration template template ID request.
  --replication-server-instance-type: string # Update replication configuration template Replication Server instance type request.
  --replication-servers-security-groups-i-ds: list<string> # Update replication configuration template Replication Server Security groups IDs request.
  --staging-area-subnet-id: string # Update replication configuration template Staging Area subnet ID request.
  --staging-area-tags: record # Update replication configuration template Staging Area Tags request.
  --use-dedicated-replication-server: oneof<nothing, bool> # Update replication configuration template use dedicated Replication Server request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateReplicationConfigurationTemplate"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: arn, var: arn}, {name: associateDefaultSecurityGroup, var: associate_default_security_group}, {name: bandwidthThrottling, var: bandwidth_throttling}, {name: createPublicIP, var: create_public_ip}, {name: dataPlaneRouting, var: data_plane_routing}, {name: defaultLargeStagingDiskType, var: default_large_staging_disk_type}, {name: ebsEncryption, var: ebs_encryption}, {name: ebsEncryptionKeyArn, var: ebs_encryption_key_arn}, {name: replicationConfigurationTemplateID, var: replication_configuration_template_id}, {name: replicationServerInstanceType, var: replication_server_instance_type}, {name: replicationServersSecurityGroupsIDs, var: replication_servers_security_groups_i_ds}, {name: stagingAreaSubnetId, var: staging_area_subnet_id}, {name: stagingAreaTags, var: staging_area_tags}, {name: useDedicatedReplicationServer, var: use_dedicated_replication_server}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, arn: $arn, associate_default_security_group: $associate_default_security_group, bandwidth_throttling: $bandwidth_throttling, create_public_ip: $create_public_ip, data_plane_routing: $data_plane_routing, default_large_staging_disk_type: $default_large_staging_disk_type, ebs_encryption: $ebs_encryption, ebs_encryption_key_arn: $ebs_encryption_key_arn, replication_configuration_template_id: $replication_configuration_template_id, replication_server_instance_type: $replication_server_instance_type, replication_servers_security_groups_i_ds: $replication_servers_security_groups_i_ds, staging_area_subnet_id: $staging_area_subnet_id, staging_area_tags: $staging_area_tags, use_dedicated_replication_server: $use_dedicated_replication_server
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows you to change between the AGENT_BASED replication type and the SNAPSHOT_SHIPPING replication type.
#
# POST /UpdateSourceServerReplicationType
# Returns: record<applicationID: string, arn: string, dataReplicationInfo: record<dataReplicationError: record<error: string, rawError: string>, dataReplicationInitiation: record<nextAttemptDateTime: string, startDateTime: string, steps: list>, dataReplicationState: string, etaDateTime: string, lagDuration: string, lastSnapshotDateTime: string, replicatedDisks: list<record>>, fqdnForActionFramework: string, isArchived: bool, launchedInstance: record<ec2InstanceID: string, firstBoot: string, jobID: string>, lifeCycle: record<addedToServiceDateTime: string, elapsedReplicationDuration: string, firstByteDateTime: string, lastCutover: record<finalized: record, initiated: record, reverted: record>, lastSeenByServiceDateTime: string, lastTest: record<finalized: record, initiated: record, reverted: record>, state: string>, replicationType: string, sourceProperties: record<cpus: list<record>, disks: list<record>, identificationHints: record<awsInstanceID: string, fqdn: string, hostname: string, vmPath: string, vmWareUuid: string>, lastUpdatedDateTime: string, networkInterfaces: list<record>, os: record<fullString: string>, ramBytes: int, recommendedInstanceType: string>, sourceServerID: string, tags: record, userProvidedID: string, vcenterClientID: string>
# operationId: UpdateSourceServerReplicationType
export def "update-source-server-replication-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  replication_type: string@replication-type-completer # Replication type to which to update source server.
  source_server_id: string # ID of source server on which to update replication type.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateSourceServerReplicationType"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: replicationType, var: replication_type}, {name: sourceServerID, var: source_server_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, replication_type: $replication_type, source_server_id: $source_server_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update wave.
#
# POST /UpdateWave
# Returns: record<arn: string, creationDateTime: string, description: string, isArchived: bool, lastModifiedDateTime: string, name: string, tags: record, waveAggregatedStatus: record<healthStatus: string, lastUpdateDateTime: string, progressStatus: string, replicationStartedDateTime: string, totalApplications: int>, waveID: string>
# operationId: UpdateWave
export def "update-wave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --description: string # Wave description.
  --name: string # Wave name.
  wave_id: string # Wave ID.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/UpdateWave"
    header: [{name: X-Amz-Content-Sha256, var: x_amz_content_sha256}, {name: X-Amz-Date, var: x_amz_date}, {name: X-Amz-Algorithm, var: x_amz_algorithm}, {name: X-Amz-Credential, var: x_amz_credential}, {name: X-Amz-Security-Token, var: x_amz_security_token}, {name: X-Amz-Signature, var: x_amz_signature}, {name: X-Amz-SignedHeaders, var: x_amz_signed_headers}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: name, var: name}, {name: waveID, var: wave_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    x_amz_content_sha256: $x_amz_content_sha256, x_amz_date: $x_amz_date, x_amz_algorithm: $x_amz_algorithm, x_amz_credential: $x_amz_credential, x_amz_security_token: $x_amz_security_token, x_amz_signature: $x_amz_signature, x_amz_signed_headers: $x_amz_signed_headers, description: $description, name: $name, wave_id: $wave_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
