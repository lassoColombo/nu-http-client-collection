# Auto-generated client for TheTVDB API v3 v3.0.0
# Source: https://api.apis.guru/v2/specs/thetvdb.com/3.0.0/swagger.json
# Auth: --token flag or $env.THETVDB_API_V3_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "THETVDB_API_V3_TOKEN"
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-episodes-id: "record<data: record<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list<string>, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list<string>, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-languages: "record<data: table<abbreviation: string, englishName: string, id: int, name: string>>"
    get-languages-id: "record<abbreviation: string, englishName: string, id: int, name: string>"
    post-login: "record<token: string>"
    get-movies-id: "record<artworks: table<artwork_type: string, height: int, id: string, is_primary: bool, tags: string, thumb_url: string, url: string, width: int>, genres: table<id: int, name: string, url: string>, id: int, people: record<actors: list<record>, directors: list<record>, producers: list<record>, writers: list<record>>, release_dates: table<country: string, date: string, type: string>, remoteids: table<id: string, source_id: int, source_name: string, source_url: string, url: string>, runtime: int, trailers: table<name: string, url: string>, translations: table<is_primary: bool, language_code: string, name: string, overview: string, tagline: string>, url: string>"
    get-movieupdates: "record<movies: list<int>>"
    get-refresh-token: "record<token: string>"
    get-search-series: "record<data: table<aliases: list, banner: string, firstAired: string, id: int, image: string, network: string, overview: string, poster: string, seriesName: string, slug: string, status: string>>"
    get-search-series-params: "record<data: list<string>>"
    get-series-id: "record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    head-series-id: "record"
    get-series-id-actors: "record<data: table<id: int, image: string, imageAdded: string, imageAuthor: int, lastUpdated: string, name: string, role: string, seriesId: int, sortOrder: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-series-id-episodes: "record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>"
    get-series-id-episodes-query: "record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>"
    get-series-id-episodes-query-params: "record<data: list<string>>"
    get-series-id-episodes-summary: "record<airedEpisodes: string, airedSeasons: list<string>, dvdEpisodes: string, dvdSeasons: list<string>>"
    get-series-id-filter: "record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-series-id-filter-params: "record<data: list<string>>"
    get-series-id-images: "record<data: record<fanart: int, poster: int, season: int, seasonwide: int, series: int>>"
    get-series-id-images-query: "record<data: table<fileName: string, id: int, keyType: string, languageId: int, ratingsInfo: record, resolution: string, subKey: string, thumbnail: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-series-id-images-query-params: "record<data: table<keyType: string, languageId: string, resolution: list, subKey: list>>"
    get-updated-query: "record<data: table<id: int, lastUpdated: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-updated-query-params: "record<data: list<string>>"
    get-user: "record<data: record<favoritesDisplaymode: string, language: string, userName: string>>"
    get-user-favorites: "record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    delete-user-favorites-id: "record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    put-user-favorites-id: "record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>"
    get-user-ratings: "record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>"
    get-user-ratings-query: "record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>"
    get-user-ratings-query-params: "record<data: list<string>>"
    delete-user-ratings-item-type-item-id: "record<data: list<any>>"
    put-user-ratings-item-type-item-id-item-rating: "record<data: table<rating: int, ratingItemId: int, ratingType: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-episodes-id" "get-languages" "get-languages-id" "post-login" "get-movies-id" "get-movieupdates" "get-refresh-token" "get-search-series" "get-search-series-params" "get-series-id" "head-series-id" "get-series-id-actors" "get-series-id-episodes" "get-series-id-episodes-query" "get-series-id-episodes-query-params" "get-series-id-episodes-summary" "get-series-id-filter" "get-series-id-filter-params" "get-series-id-images" "get-series-id-images-query" "get-series-id-images-query-params" "get-updated-query" "get-updated-query-params" "get-user" "get-user-favorites" "delete-user-favorites-id" "put-user-favorites-id" "get-user-ratings" "get-user-ratings-query" "get-user-ratings-query-params" "delete-user-ratings-item-type-item-id" "put-user-ratings-item-type-item-id-item-rating" "commands"] | sort) } | get name | first)
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

# Returns the full information for a given episode id. __Deprecation Warning:__ The _director_ key will be deprecated in favor of the new _directors_ key in a future release.
#
# GET /episodes/{id}
# Returns: record<data: record<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list<string>, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list<string>, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-episodes-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/episodes/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All available languages. These language abbreviations can be used in the `Accept-Language` header for routes that return translation records.
#
# GET /languages
# Returns: record<data: table<abbreviation: string, englishName: string, id: int, name: string>>
export def "get-languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/languages"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Information about a particular language, given the language ID.
#
# GET /languages/{id}
# Returns: record<abbreviation: string, englishName: string, id: int, name: string>
export def "get-languages-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/languages/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a session token to be included in the rest of the requests. Note that API key authentication is required for all subsequent requests and user auth is required for routes in the `User` section
#
# POST /login
# Returns: record<token: string>
export def "post-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string
  --userkey: string
  --username: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/login"
    body: {content_type: "application/json", kind: json, fields: [{name: apikey, var: apikey}, {name: userkey, var: userkey}, {name: username, var: username}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, userkey: $userkey, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a movies records that contains all information known about a particular movies id.
#
# GET /movies/{id}
# Returns: record<artworks: table<artwork_type: string, height: int, id: string, is_primary: bool, tags: string, thumb_url: string, url: string, width: int>, genres: table<id: int, name: string, url: string>, id: int, people: record<actors: list<record>, directors: list<record>, producers: list<record>, writers: list<record>>, release_dates: table<country: string, date: string, type: string>, remoteids: table<id: string, source_id: int, source_name: string, source_url: string, url: string>, runtime: int, trailers: table<name: string, url: string>, translations: table<is_primary: bool, language_code: string, name: string, overview: string, tagline: string>, url: string>
export def "get-movies-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/movies/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all movies ids updated since a given timestamp.
#
# GET /movieupdates
# Returns: record<movies: list<int>>
export def "get-movieupdates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Epoch time to start your date range. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/movieupdates"
    query: [{name: since, var: since, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    since: $since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Refreshes your current, valid JWT token and returns a new token. Hit this route so that you do not have to post to `/login` with your API key and credentials once you have already been authenticated.
#
# GET /refresh_token
# Returns: record<token: string>
export def "get-refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/refresh_token"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Allows the user to search for a series based on the following parameters.
#
# GET /search/series
# Returns: record<data: table<aliases: list, banner: string, firstAired: string, id: int, image: string, network: string, overview: string, poster: string, seriesName: string, slug: string, status: string>>
export def "get-search-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the series to search for.
  --imdb-id: string # IMDB id of the series
  --zap2it-id: string # Zap2it ID of the series to search for.
  --slug: string # Slug from site URL of series (https://www.thetvdb.com/series/$SLUG)
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/series"
    query: [{name: name, var: name}, {name: imdbId, var: imdb_id}, {name: zap2itId, var: zap2it_id}, {name: slug, var: slug}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, imdb_id: $imdb_id, zap2it_id: $zap2it_id, slug: $slug, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of parameters to query by in the `/search/series` route.
#
# GET /search/series/params
# Returns: record<data: list<string>>
export def "get-search-series-params" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/series/params"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a series records that contains all information known about a particular series id.
#
# GET /series/{id}
# Returns: record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-series-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns header information only about the given series ID.
#
# HEAD /series/{id}
# Returns: record
export def "head-series-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: head
    path: "/series/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns actors for the given series id
#
# GET /series/{id}/actors
# Returns: record<data: table<id: int, image: string, imageAdded: string, imageAuthor: int, lastUpdated: string, name: string, role: string, seriesId: int, sortOrder: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-series-id-actors" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/actors"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# All episodes for a given series. Paginated with 100 results per page.
#
# GET /series/{id}/episodes
# Returns: record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>
export def "get-series-id-episodes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Page of results to fetch. Defaults to page 1 if not provided.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/episodes"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, page: $page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This route allows the user to query against episodes for the given series. The response is a paginated array of episode records.
#
# GET /series/{id}/episodes/query
# Returns: record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>
export def "get-series-id-episodes-query" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --absolute-number: string # Absolute number of the episode
  --aired-season: string # Aired season number
  --aired-episode: string # Aired episode number
  --dvd-season: string # DVD season number
  --dvd-episode: string # DVD episode number
  --imdb-id: string # IMDB id of the series
  --page: string # Page of results to fetch. Defaults to page 1 if not provided.
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/episodes/query"
    path_params: [{name: id, var: id}]
    query: [{name: absoluteNumber, var: absolute_number}, {name: airedSeason, var: aired_season}, {name: airedEpisode, var: aired_episode}, {name: dvdSeason, var: dvd_season}, {name: dvdEpisode, var: dvd_episode}, {name: imdbId, var: imdb_id}, {name: page, var: page}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, absolute_number: $absolute_number, aired_season: $aired_season, aired_episode: $aired_episode, dvd_season: $dvd_season, dvd_episode: $dvd_episode, imdb_id: $imdb_id, page: $page, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the allowed query keys for the `/series/{id}/episodes/query` route
#
# GET /series/{id}/episodes/query/params
# Returns: record<data: list<string>>
export def "get-series-id-episodes-query-params" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/episodes/query/params"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary of the episodes and seasons available for the series. __Note__: Season "0" is for all episodes that are considered to be specials.
#
# GET /series/{id}/episodes/summary
# Returns: record<airedEpisodes: string, airedSeasons: list<string>, dvdEpisodes: string, dvdSeasons: list<string>>
export def "get-series-id-episodes-summary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/episodes/summary"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a series records, filtered by the supplied comma-separated list of keys. Query keys can be found at the `/series/{id}/filter/params` route.
#
# GET /series/{id}/filter
# Returns: record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-series-id-filter" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: string # Comma-separated list of keys to filter by (required)
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/filter"
    path_params: [{name: id, var: id}]
    query: [{name: keys, var: keys, required: true}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, keys: $keys, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the list of keys available for the `/series/{id}/filter` route
#
# GET /series/{id}/filter/params
# Returns: record<data: list<string>>
export def "get-series-id-filter-params" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/filter/params"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a summary of the images for a particular series
#
# GET /series/{id}/images
# Returns: record<data: record<fanart: int, poster: int, season: int, seasonwide: int, series: int>>
export def "get-series-id-images" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/images"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query images for the given series ID.
#
# GET /series/{id}/images/query
# Returns: record<data: table<fileName: string, id: int, keyType: string, languageId: int, ratingsInfo: record, resolution: string, subKey: string, thumbnail: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-series-id-images-query" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-type: string # Type of image you're querying for (fanart, poster, etc. See ../images/query/params for more details).
  --resolution: string # Resolution to filter by (1280x1024, for example)
  --sub-key: string # Subkey for the above query keys. See /series/{id}/images/query/params for more information
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/images/query"
    path_params: [{name: id, var: id}]
    query: [{name: keyType, var: key_type}, {name: resolution, var: resolution}, {name: subKey, var: sub_key}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, key_type: $key_type, resolution: $resolution, sub_key: $sub_key, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the allowed query keys for the `/series/{id}/images/query` route. Contains a parameter record for each unique `keyType`, listing values that will return results.
#
# GET /series/{id}/images/query/params
# Returns: record<data: table<keyType: string, languageId: string, resolution: list, subKey: list>>
export def "get-series-id-images-query-params" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/series/{id}/images/query/params"
    path_params: [{name: id, var: id}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of series that have changed in a maximum of one week blocks since the provided `fromTime`. The user may specify a `toTime` to grab results for less than a week. Any timespan larger than a week will be reduced down to one week automatically.
#
# GET /updated/query
# Returns: record<data: table<id: int, lastUpdated: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-updated-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # Epoch time to start your date range. (required)
  --to-time: string # Epoch time to end your date range. Must be one week from `fromTime`.
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/updated/query"
    query: [{name: fromTime, var: from_time, required: true}, {name: toTime, var: to_time}]
    header: [{name: Accept-Language, var: accept_language}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    from_time: $from_time, to_time: $to_time, accept_language: $accept_language
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of valid query keys for the `/updated/query/params` route.
#
# GET /updated/query/params
# Returns: record<data: list<string>>
export def "get-updated-query-params" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/updated/query/params"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns basic information about the currently authenticated user.
#
# GET /user
# Returns: record<data: record<favoritesDisplaymode: string, language: string, userName: string>>
export def "get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of favorite series for a given user, will be a blank array if no favorites exist.
#
# GET /user/favorites
# Returns: record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "get-user-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/favorites"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the given series ID from the user’s favorite’s list and returns the updated list.
#
# DELETE /user/favorites/{id}
# Returns: record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "delete-user-favorites-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/user/favorites/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds the supplied series ID to the user’s favorite’s list and returns the updated list.
#
# PUT /user/favorites/{id}
# Returns: record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>>
export def "put-user-favorites-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/user/favorites/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of ratings for the given user.
#
# GET /user/ratings
# Returns: record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>
export def "get-user-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/ratings"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns an array of ratings for a given user that match the query.
#
# GET /user/ratings/query
# Returns: record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>>
export def "get-user-ratings-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-type: string # Item to query. Can be either 'series', 'episode', or 'banner' (format: string)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/ratings/query"
    query: [{name: itemType, var: item_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_type: $item_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns a list of query params for use in the `/user/ratings/query` route.
#
# GET /user/ratings/query/params
# Returns: record<data: list<string>>
export def "get-user-ratings-query-params" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/ratings/query/params"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This route deletes a given rating of a given type.
#
# DELETE /user/ratings/{itemType}/{itemId}
# Returns: record<data: list<any>>
export def "delete-user-ratings-item-type-item-id" [
  item_type: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/user/ratings/{itemType}/{itemId}"
    path_params: [{name: itemType, var: item_type}, {name: itemId, var: item_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_type: $item_type, item_id: $item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This route updates a given rating of a given type.
#
# PUT /user/ratings/{itemType}/{itemId}/{itemRating}
# Returns: record<data: table<rating: int, ratingItemId: int, ratingType: string>>
export def "put-user-ratings-item-type-item-id-item-rating" [
  item_type: string
  item_id: int
  item_rating: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/user/ratings/{itemType}/{itemId}/{itemRating}"
    path_params: [{name: itemType, var: item_type}, {name: itemId, var: item_id}, {name: itemRating, var: item_rating}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_type: $item_type, item_id: $item_id, item_rating: $item_rating
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
