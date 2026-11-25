# Auto-generated client for Growth Services v1
# Source: https://api.apis.guru/v2/specs/i-cue.solutions/v1/openapi.json
# Auth: --token flag or $env.GROWTH_SERVICES_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "GROWTH_SERVICES_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: []
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
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def method-completer [] { ["icueMLN" "icueMLO" "icueMLP"] }
def error-type-completer [] { ["MeanAbsoluteError" "MeanAbsolutePercentageError" "MeanSquaredError" "MedianAbsoluteDeviation" "None"] }
def method-completer-1 [] { ["AutoBestPick" "BoxJenkins" "Croston" "DoubleExponentialSmoothing" "HoltWinters" "SimpleMovingAverage" "SingleExponentialSmoothing" "iCUE1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-administration-entity: "table<address: string, dbConnection: string, email: string, id: int, isActive: bool, name: string, token: string>"
    post-administration-entity: "string"
    post-administration-file-to-json: "record<data: table<historyValues: list, timeSeriesId: string>, planningLevelId: string, startDate: string>"
    get-administration-model: "table<key: string, name: string, queue: string, replyQueue: string>"
    post-administration-model: "record<key: string, name: string, queue: string, replyQueue: string>"
    get-administration-model-entity-id: "table<key: string, name: string, queue: string, replyQueue: string>"
    post-administration-model-entity-id: "record<key: string, name: string, queue: string, replyQueue: string>"
    post-administration-token: "string"
    post-administration-user: "string"
    post-forecast: "record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, method: string, timeSeriesId: string>>"
    post-forecast-ai: "record<jobId: int>"
    post-forecast-ai-history-and-forecast: "record<jobId: int>"
    post-forecast-file-to-forecast: "record<jobId: int>"
    post-forecast-forecast-bottom-up: "record<forecastData: table<date: string, value: float>, hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>>"
    post-forecast-full-detail: "record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, historyData: list, method: string, optimalParameters: record, outliers: list, timeSeriesId: string>>"
    post-forecast-history-and-forecast: "record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, historyData: list, method: string, timeSeriesId: string>>"
    post-forecast-optimal-parameter: "record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<method: string, optimalParameters: record, timeSeriesId: string>>"
    post-forecast-rerun: "record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, method: string, timeSeriesId: string>>"
    get-hyperparameter: "record<abcClassificationThresholdA: float, abcClassificationThresholdB: float, abcClassificationThresholdC: float, discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int, xyzClassificationThresholdX: float, xyzClassificationThresholdY: float, xyzClassificationThresholdZ: float>"
    post-lifecycle-many-to-one: "record<historyValues: list<float>, timeSeriesId: string>"
    post-lifecycle-one-to-one: "record<historyValues: list<float>, timeSeriesId: string>"
    post-outlier: "table<outliers: list<record>, timeSeriesId: string>"
    post-portfolio: "table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>"
    post-portfolio-abc: "table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float>"
    post-portfolio-forecast-performance-rewind: "record<hyperparameters: record<costOfError: float, discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int, rewindTimeFrame: int>, timeSeries: table<customerError: float, errorDiff: float, icueError: float, timeSeries: string, totalCost: float, useIcue: bool>, totalCost: float>"
    post-portfolio-xyz: "table<id: string, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>"
    get-report-performance-sku-rationalization-planning-level-id: "table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-administration-entity" "post-administration-entity" "put-administration-entity" "delete-administration-entity-id" "post-administration-file-to-json" "get-administration-model" "post-administration-model" "get-administration-model-entity-id" "post-administration-model-entity-id" "post-administration-planning-level-lock" "delete-administration-planning-level-entity-id-id" "post-administration-token" "post-administration-user" "put-administration-user" "put-administration-user-lock" "get-administration-user-entity-id" "delete-administration-user-entity-id-id" "post-forecast" "post-forecast-ai" "post-forecast-ai-history-and-forecast" "post-forecast-file-to-forecast" "post-forecast-forecast-bottom-up" "post-forecast-forecast-top-down" "post-forecast-full-detail" "post-forecast-history-and-forecast" "post-forecast-optimal-parameter" "post-forecast-rerun" "get-forecast-result-job-id" "get-forecast-status-job-id" "get-hyperparameter" "post-hyperparameter" "post-inventory-amazon-ipi" "post-inventory-caryying-cost" "post-inventory-eoq" "post-inventory-fill-rate" "post-inventory-financial-imapct-forecast-accuracy" "post-inventory-inventory-turnover" "post-inventory-ltd" "post-inventory-moq" "post-inventory-optimal-service-level" "post-inventory-reorder-point" "post-inventory-safety-stock" "post-inventory-service-level" "post-inventory-turns" "post-lifecycle-many-to-one" "post-lifecycle-one-to-one" "post-outlier" "post-portfolio" "post-portfolio-abc" "post-portfolio-file-to-portfolio" "post-portfolio-forecast-performance-rewind" "post-portfolio-xyz" "post-pricing-bundle-pricing" "post-pricing-competitive-pricing" "post-pricing-cost-plus-pricing" "post-pricing-decoy-pricing" "post-pricing-odd-pricing" "post-pricing-penetration-pricing" "post-pricing-price-elasticity-of-demand" "get-report-performance-sku-rationalization-planning-level-id" "get-report-performance-planning-level-id" "get-report-planning-level-organization" "get-report-planning-level-user" "get-report-user" "commands"] | sort) } | get name | first)
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

# Get all organizations
#
# GET /administration/entity
# Returns: table<address: string, dbConnection: string, email: string, id: int, isActive: bool, name: string, token: string>
export def "get-administration-entity" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/administration/entity"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create organization
#
# POST /administration/entity
# Returns: string
export def "post-administration-entity" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --address: string # nullable
  --email: string # nullable
  --name: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/administration/entity"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: email, var: email}, {name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, address: $address, email: $email, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Pause organization
#
# PUT /administration/entity
export def "put-administration-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
  --id: int # format: int32
  --is-active: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/administration/entity"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: id, var: id}, {name: isActive, var: is_active}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, id: $id, is_active: $is_active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete organization
#
# DELETE /administration/entity/{id}
export def "delete-administration-entity-id" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/administration/entity/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transform data file to JSON format
#
# POST /administration/file-to-json
# Returns: record<data: table<historyValues: list, timeSeriesId: string>, planningLevelId: string, startDate: string>
export def "post-administration-file-to-json" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  file: string # format: binary
  periodicity: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/administration/file-to-json"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}, {name: Periodicity, var: periodicity}], files: [File]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file, periodicity: $periodicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all common Models
#
# GET /administration/model
# Returns: table<key: string, name: string, queue: string, replyQueue: string>
export def "get-administration-model" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/administration/model"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register new forecasting model
#
# POST /administration/model
# Returns: record<key: string, name: string, queue: string, replyQueue: string>
export def "post-administration-model" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --key: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/administration/model"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Models for Organization
#
# GET /administration/model/{entityId}
# Returns: table<key: string, name: string, queue: string, replyQueue: string>
export def "get-administration-model-entity-id" [
  entity_id: int
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/administration/model/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Register new forecasting model
#
# POST /administration/model/{entityId}
# Returns: record<key: string, name: string, queue: string, replyQueue: string>
export def "post-administration-model-entity-id" [
  entity_id: int
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --key: string # nullable
  --name: string # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/administration/model/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: key, var: key}, {name: name, var: name}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, hdr_token: $hdr_token, key: $key, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lock planning level
#
# POST /administration/planning-level/lock
export def "post-administration-planning-level-lock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/administration/planning-level/lock"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete planning level
#
# DELETE /administration/planning-level/{entityId}/{id}
export def "delete-administration-planning-level-entity-id-id" [
  entity_id: int
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/administration/planning-level/{entityId}/{id}"
    path_params: [{name: entityId, var: entity_id}, {name: id, var: id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Issue a token
#
# POST /administration/token
# Returns: string
export def "post-administration-token" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --entity-token: string # format: uuid
  --expiration-date: string # format: date-time
  --user-token: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/administration/token"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityToken, var: entity_token}, {name: expirationDate, var: expiration_date}, {name: userToken, var: user_token}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, entity_token: $entity_token, expiration_date: $expiration_date, user_token: $user_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Create user
#
# POST /administration/user
# Returns: string
export def "post-administration-user" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --email: string # nullable
  --entity-token: string # format: uuid
  --firstname: string # nullable
  --lastname: string # nullable
  --phone: string # nullable
]: any -> any {
  $in | http-request {
    method: post
    path: "/administration/user"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: entityToken, var: entity_token}, {name: firstname, var: firstname}, {name: lastname, var: lastname}, {name: phone, var: phone}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, email: $email, entity_token: $entity_token, firstname: $firstname, lastname: $lastname, phone: $phone
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update user
#
# PUT /administration/user
export def "put-administration-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: put
    path: "/administration/user"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lock user
#
# PUT /administration/user/lock
export def "put-administration-user-lock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
  --entity-id: int # format: int32
  --id: int # format: int32
  --is-active: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/administration/user/lock"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: entityId, var: entity_id}, {name: id, var: id}, {name: isActive, var: is_active}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, entity_id: $entity_id, id: $id, is_active: $is_active
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all users
#
# GET /administration/user/{entityId}
export def "get-administration-user-entity-id" [
  entity_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/administration/user/{entityId}"
    path_params: [{name: entityId, var: entity_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user
#
# DELETE /administration/user/{entityId}/{id}
export def "delete-administration-user-entity-id-id" [
  entity_id: int
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: delete
    path: "/administration/user/{entityId}/{id}"
    path_params: [{name: entityId, var: entity_id}, {name: id, var: id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    entity_id: $entity_id, id: $id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forecasts only, for faster results
#
# POST /forecast
# Returns: record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, method: string, timeSeriesId: string>>
export def "post-forecast" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Forecast utilizing advanced machine learning models
#
# POST /forecast/AI
# Returns: record<jobId: int>
export def "post-forecast-ai" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string@method-completer # e.g. icueMLP | icueMLO
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/AI"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# History and forecast utilizing advanced machine learning models
#
# POST /forecast/AI/history-and-forecast
# Returns: record<jobId: int>
export def "post-forecast-ai-history-and-forecast" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string@method-completer # e.g. icueMLP | icueMLO
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/AI/history-and-forecast"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Forecast from file
#
# POST /forecast/file-to-forecast
# Returns: record<jobId: int>
export def "post-forecast-file-to-forecast" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --discard-data: oneof<nothing, bool>
  --error-type: string@error-type-completer
  file: string # format: binary
  --hold-out-period: int # format: int32
  method: string@method-completer-1 # e.g. iCUE1
  --no-fcst: int # format: int32
  --outlier-detection: oneof<nothing, bool>
  --periodicity: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/file-to-forecast"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: DiscardData, var: discard_data}, {name: ErrorType, var: error_type}, {name: File, var: file}, {name: HoldOutPeriod, var: hold_out_period}, {name: Method, var: method}, {name: NoFcst, var: no_fcst}, {name: OutlierDetection, var: outlier_detection}, {name: Periodicity, var: periodicity}], files: [File]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, discard_data: $discard_data, error_type: $error_type, file: $file, hold_out_period: $hold_out_period, method: $method, no_fcst: $no_fcst, outlier_detection: $outlier_detection, periodicity: $periodicity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Bottom up forecasting
#
# POST /forecast/forecast-bottom-up
# Returns: record<forecastData: table<date: string, value: float>, hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>>
export def "post-forecast-forecast-bottom-up" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/forecast-bottom-up"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Top down forecasting
#
# POST /forecast/forecast-top-down
export def "post-forecast-forecast-top-down" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> any {
  $in | http-request {
    method: post
    path: "/forecast/forecast-top-down"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Full forecast result details, including error, trend seasonality and outlier
#
# POST /forecast/full-detail
# Returns: record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, historyData: list, method: string, optimalParameters: record, outliers: list, timeSeriesId: string>>
export def "post-forecast-full-detail" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/full-detail"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# History and forecast for fast timeseries view
#
# POST /forecast/history-and-forecast
# Returns: record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, historyData: list, method: string, timeSeriesId: string>>
export def "post-forecast-history-and-forecast" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/history-and-forecast"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get optimal parameter per method
#
# POST /forecast/optimal-parameter
# Returns: record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<method: string, optimalParameters: record, timeSeriesId: string>>
export def "post-forecast-optimal-parameter" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --override: oneof<nothing, bool> # e.g. false
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/optimal-parameter"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: method, var: method}, {name: override, var: override}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, method: $method, override: $override, params: $params, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Rerun previously uploaded planning level
#
# POST /forecast/rerun
# Returns: record<hyperparameters: record<discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int>, timeSeries: table<error: float, forecastData: list, method: string, timeSeriesId: string>>
export def "post-forecast-rerun" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  method: string # e.g. iCUE1
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: int # format: int32
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/forecast/rerun"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: method, var: method}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, method: $method, params: $params, planning_level_id: $planning_level_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Forecast result
#
# GET /forecast/result/{jobId}
export def "get-forecast-result-job-id" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/forecast/result/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Forecast status
#
# GET /forecast/status/{jobId}
export def "get-forecast-status-job-id" [
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/forecast/status/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get hyperparameters
#
# GET /hyperparameter
# Returns: record<abcClassificationThresholdA: float, abcClassificationThresholdB: float, abcClassificationThresholdC: float, discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int, xyzClassificationThresholdX: float, xyzClassificationThresholdY: float, xyzClassificationThresholdZ: float>
export def "get-hyperparameter" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/hyperparameter"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set hyperparameters
#
# POST /hyperparameter
export def "post-hyperparameter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
  --abc-classification-threshold-a: float # nullable, format: double, e.g. 0.8
  --abc-classification-threshold-b: float # nullable, format: double, e.g. 0.95
  --abc-classification-threshold-c: float # nullable, format: double, e.g. 0.95
  --discard-data: oneof<nothing, bool> # nullable, e.g. false
  --error-type: string@error-type-completer # e.g. MeanAbsolutePercentageError
  --hold-out-period: int # nullable, format: int32, e.g. 4
  --no-fcst: int # nullable, format: int32, e.g. 18
  --outlier-detection: oneof<nothing, bool> # nullable, e.g. true
  --periodicity: int # nullable, format: int32, e.g. 12
  --xyz-classification-threshold-x: float # nullable, format: double, e.g. 0.3
  --xyz-classification-threshold-y: float # nullable, format: double, e.g. 0.6
  --xyz-classification-threshold-z: float # nullable, format: double, e.g. 0.6
]: any -> any {
  $in | http-request {
    method: post
    path: "/hyperparameter"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: abcClassificationThresholdA, var: abc_classification_threshold_a}, {name: abcClassificationThresholdB, var: abc_classification_threshold_b}, {name: abcClassificationThresholdC, var: abc_classification_threshold_c}, {name: discardData, var: discard_data}, {name: errorType, var: error_type}, {name: holdOutPeriod, var: hold_out_period}, {name: noFcst, var: no_fcst}, {name: outlierDetection, var: outlier_detection}, {name: periodicity, var: periodicity}, {name: xyzClassificationThresholdX, var: xyz_classification_threshold_x}, {name: xyzClassificationThresholdY, var: xyz_classification_threshold_y}, {name: xyzClassificationThresholdZ, var: xyz_classification_threshold_z}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, abc_classification_threshold_a: $abc_classification_threshold_a, abc_classification_threshold_b: $abc_classification_threshold_b, abc_classification_threshold_c: $abc_classification_threshold_c, discard_data: $discard_data, error_type: $error_type, hold_out_period: $hold_out_period, no_fcst: $no_fcst, outlier_detection: $outlier_detection, periodicity: $periodicity, xyz_classification_threshold_x: $xyz_classification_threshold_x, xyz_classification_threshold_y: $xyz_classification_threshold_y, xyz_classification_threshold_z: $xyz_classification_threshold_z
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate Amazon Inventory Performance Index (IPI)
#
# POST /inventory/amazon-ipi
export def "post-inventory-amazon-ipi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/amazon-ipi"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Carrying Cost
#
# POST /inventory/caryying-cost
export def "post-inventory-caryying-cost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/caryying-cost"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate economic order quantity
#
# POST /inventory/eoq
export def "post-inventory-eoq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/eoq"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate fill rate
#
# POST /inventory/fill-rate
export def "post-inventory-fill-rate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/fill-rate"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate financial impact of forecast accuracy
#
# POST /inventory/financial-imapct-forecast-accuracy
export def "post-inventory-financial-imapct-forecast-accuracy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/financial-imapct-forecast-accuracy"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inventroy Turn-over
#
# POST /inventory/inventory-turnover
export def "post-inventory-inventory-turnover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/inventory-turnover"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate lead time demand
#
# POST /inventory/ltd
export def "post-inventory-ltd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/ltd"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate minimum order quantity
#
# POST /inventory/moq
export def "post-inventory-moq" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/moq"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate optimal service level
#
# POST /inventory/optimal-service-level
export def "post-inventory-optimal-service-level" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/optimal-service-level"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Re-order Point
#
# POST /inventory/reorder-point
export def "post-inventory-reorder-point" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/reorder-point"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Safety Stock
#
# POST /inventory/safety-stock
export def "post-inventory-safety-stock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/safety-stock"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate service level
#
# POST /inventory/service-level
export def "post-inventory-service-level" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/service-level"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Calculate inventory turns
#
# POST /inventory/turns
export def "post-inventory-turns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/inventory/turns"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Map from old product to new product to create artifical history
#
# POST /lifecycle/many-to-one
# Returns: record<historyValues: list<float>, timeSeriesId: string>
export def "post-lifecycle-many-to-one" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  --ratios: list<float> # nullable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lifecycle/many-to-one"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: ratios, var: ratios}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, ratios: $ratios
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Map from old product to new product to create artifical history
#
# POST /lifecycle/one-to-one
# Returns: record<historyValues: list<float>, timeSeriesId: string>
export def "post-lifecycle-one-to-one" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: record # shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  --ratio: float # format: double, e.g. 15
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/lifecycle/one-to-one"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: ratio, var: ratio}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, ratio: $ratio
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get outlier
#
# POST /outlier
# Returns: table<outliers: list<record>, timeSeriesId: string>
export def "post-outlier" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/outlier"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ABCxyz Analysis
#
# POST /portfolio
# Returns: table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>
export def "post-portfolio" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ABC Analysis
#
# POST /portfolio/abc
# Returns: table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float>
export def "post-portfolio-abc" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/abc"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# ABCxyz Analysis
#
# POST /portfolio/file-to-portfolio
export def "post-portfolio-file-to-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
  file: string # format: binary
]: any -> any {
  $in | http-request {
    method: post
    path: "/portfolio/file-to-portfolio"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: File, var: file}], files: [File]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Planning level rewind to calculate and measure performance potential (internal versus iCUE).
#
# POST /portfolio/forecast-performance-rewind
# Returns: record<hyperparameters: record<costOfError: float, discardData: bool, errorType: string, holdOutPeriod: int, noFcst: int, periodicity: int, rewindTimeFrame: int>, timeSeries: table<customerError: float, errorDiff: float, icueError: float, timeSeries: string, totalCost: float, useIcue: bool>, totalCost: float>
export def "post-portfolio-forecast-performance-rewind" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --cost-of-error: float # format: double, e.g. 200
  --data: list # nullable — item shape: {forecastValues?: list<float>, historyValues?: list<float>, timeSeriesId?: string}
  method: string # e.g. iCUE1
  --params: record # shape: {discardData: bool, errorType: "MeanAbsolutePercentageError"|"MeanSquaredError"|"MeanAbsoluteError"|"MedianAbsoluteDeviation"|"None", holdOutPeriod: int, noFcst: int, outlierDetection: bool, periodicity: int}
  planning_level_id: string
  rewind_time_frame: int # format: int32, e.g. 12
  start_date: string # e.g. 1/16/2016
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/forecast-performance-rewind"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: costOfError, var: cost_of_error}, {name: data, var: data}, {name: method, var: method}, {name: params, var: params}, {name: planningLevelId, var: planning_level_id}, {name: rewindTimeFrame, var: rewind_time_frame}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, cost_of_error: $cost_of_error, data: $data, method: $method, params: $params, planning_level_id: $planning_level_id, rewind_time_frame: $rewind_time_frame, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# xyz Analysis
#
# POST /portfolio/xyz
# Returns: table<id: string, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>
export def "post-portfolio-xyz" [
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
  --hdr-token: string # User Authentication Token (spec name: Token)
  --data: list # nullable — item shape: {historyValues?: list<float>, timeSeriesId?: string}
  planning_level_id: string
  start_date: string # e.g. 1/16/2016
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolio/xyz"
    header: [{name: Token, var: hdr_token}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}, {name: planningLevelId, var: planning_level_id}, {name: startDate, var: start_date}]}
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token, data: $data, planning_level_id: $planning_level_id, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Bundle pricing
#
# POST /pricing/bundle-pricing
export def "post-pricing-bundle-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/bundle-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/competitive-pricing
export def "post-pricing-competitive-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/competitive-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/cost-plus-pricing
export def "post-pricing-cost-plus-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/cost-plus-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/decoy-pricing
export def "post-pricing-decoy-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/decoy-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/odd-pricing
export def "post-pricing-odd-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/odd-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/penetration-pricing
export def "post-pricing-penetration-pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/penetration-pricing"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /pricing/price-elasticity-of-demand
export def "post-pricing-price-elasticity-of-demand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: post
    path: "/pricing/price-elasticity-of-demand"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# SKU rationalization report
#
# GET /report/performance/sku-rationalization/{planningLevelId}
# Returns: table<abc12: string, abc12Value: float, abc6: string, abc6Value: float, abc9: string, abc9Value: float, id: string, thresholdA: float, thresholdB: float, thresholdC: float, thresholdX: float, thresholdY: float, thresholdZ: float, xyz12: string, xyz12Value: float, xyz6: string, xyz6Value: float, xyz9: string, xyz9Value: float>
export def "get-report-performance-sku-rationalization-planning-level-id" [
  planning_level_id: int
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
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/report/performance/sku-rationalization/{planningLevelId}"
    path_params: [{name: planningLevelId, var: planning_level_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json", "text/json", "text/plain"]
    ok: [200]
    auth: bearer
  } {
    planning_level_id: $planning_level_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Month over month performance per planning level
#
# GET /report/performance/{planningLevelId}
export def "get-report-performance-planning-level-id" [
  planning_level_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/report/performance/{planningLevelId}"
    path_params: [{name: planningLevelId, var: planning_level_id}]
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    planning_level_id: $planning_level_id, hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of plannign levels by organization
#
# GET /report/planning-level/organization
export def "get-report-planning-level-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/report/planning-level/organization"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of plannign levels by user
#
# GET /report/planning-level/user
export def "get-report-planning-level-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/report/planning-level/user"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get usage statistics per user
#
# GET /report/user
export def "get-report-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-token: string # User Authentication Token (spec name: Token)
]: nothing -> any {
  http-request {
    method: get
    path: "/report/user"
    header: [{name: Token, var: hdr_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    hdr_token: $hdr_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
