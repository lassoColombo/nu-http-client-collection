# Auto-generated client for Yodlee Core APIs v1.1.0
# Source: https://api.apis.guru/v2/specs/yodlee.com/1.1.0/openapi.json
# Auth: --token flag or $env.YODLEE_CORE_APIS_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "YODLEE_CORE_APIS_TOKEN"
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
def event-name-completer [] { ["AUTO_REFRESH_UPDATES" "DATA_UPDATES" "REFRESH"] }
def aggregation-source-completer [] { ["SYSTEM" "USER"] }
def source-completer [] { ["SYSTEM" "USER"] }
def action-completer [] { ["run"] }
def container-completer [] { ["bank" "creditCard" "insurance" "investment" "loan" "otherAssets" "otherLiabilities" "realEstate" "reward"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-all-accounts: "record<account: table<\"401kLoan\": record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>>"
    create-manual-account: "record<account: table<accountName: string, accountNumber: string, id: int>>"
    evaluate-address: "record<address: table<address1: string, address2: string, address3: string, city: string, country: string, sourceType: string, state: string, street: string, type: string, zip: string>, isValidAddress: bool>"
    get-historical-balances: "record<account: table<historicalBalances: list, id: int>>"
    get-account: "record<account: table<\"401kLoan\": record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>>"
    get-api-keys: "record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>>"
    generate-api-key: "record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>>"
    generate-access-token: "record<token: record<accessToken: string, expiresIn: int, issuedAt: string>>"
    get-subscribed-events: "record<event: table<callbackUrl: string, name: string>>"
    cobrand-login: "record<applicationId: string, cobrandId: int, locale: string, session: record<cobSession: string>>"
    get-public-key: "record<keyAlias: string, keyAsPemString: string>"
    get-subscribed-notification-events: "record<event: table<callbackUrl: string, name: string>>"
    get-public-encryption-key: "record<publicKey: record<alias: string, key: string>>"
    get-data-extracts-events: "record<event: record<data: record<fromDate: string, toDate: string, userCount: int, userData: list>, info: string>>"
    get-data-extracts-user-data: "record<userData: table<account: list, holding: list, providerAccount: list, totalTransactionsCount: int, transaction: list, user: record>>"
    get-holding-summary: "record<holdingSummary: table<account: list, classificationType: string, classificationValue: string, holding: list, value: record>, link: record<holdings: string>>"
    get-networth: "record<networth: table<asset: record, date: string, historicalBalances: list, liability: record, networth: record>>"
    get-transaction-summary: "record<links: record<transactions: string>, transactionSummary: table<categorySummary: list, categoryType: string, creditTotal: record, debitTotal: record, links: record>>"
    get-documents: "record<document: table<accountID: int, docType: string, formType: string, id: string, lastUpdated: string, name: string, source: string, status: string>>"
    download-document: "record<document: table<docContent: string, id: string>>"
    get-holdings: "record<holding: table<accountId: int, accruedIncome: record, accruedInterest: record, assetClassification: list, contractQuantity: float, costBasis: record, couponRate: float, createdDate: string, cusipNumber: string, description: string, enrichedDescription: string, exercisedQuantity: float, expirationDate: string, grantDate: string, holdingType: string, id: int, interestRate: float, isShort: bool, isin: string, lastUpdated: string, matchStatus: string, maturityDate: string, optionType: string, price: record, providerAccountId: int, quantity: float, securityStyle: string, securityType: string, sedol: string, spread: record, strikePrice: record, symbol: string, term: string, unvestedQuantity: float, unvestedValue: record, value: record, vestedQuantity: float, vestedSharesExercisable: float, vestedValue: record, vestingDate: string>>"
    get-asset-classification-list: "record<assetClassificationList: table<classificationType: string, classificationValue: list>>"
    get-holding-type-list: "record<holdingType: list<string>>"
    get-securities: "record<holding: table<id: string, security: record>>"
    get-all-provider-accounts: "record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>>"
    edit-credentials-or-refresh-provider-account: "record<providerAccount: table<aggregationSource: string, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, providerId: int, requestId: string, status: string>>"
    get-provider-account-profiles: "record<providerAccount: table<id: int, profile: list>>"
    get-provider-account: "record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>>"
    get-all-providers: "record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, forgetPasswordUrl: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginHelp: string, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>>"
    get-providers-count: "record<provider: record<TOTAL: record<count: int>>>"
    get-provider: "record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginForm: list, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>>"
    get-statements: "record<statement: table<accountId: int, amountDue: record, apr: float, billingPeriodEnd: string, billingPeriodStart: string, cashAdvance: record, cashApr: float, dueDate: string, id: int, interestAmount: record, isLatest: bool, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, loanBalance: record, minimumPayment: record, newCharges: record, principalAmount: record, statementDate: string>>"
    get-transactions: "record<transaction: table<CONTAINER: string, accountId: int, amount: record, baseType: string, category: string, categoryId: int, categorySource: string, categoryType: string, checkNumber: string, commission: record, createdDate: string, cusipNumber: string, date: string, description: record, detailCategoryId: int, highLevelCategoryId: int, holdingDescription: string, id: int, interest: record, isManual: bool, isin: string, lastUpdated: string, memo: string, merchant: record, parentCategoryId: int, postDate: string, price: record, principal: record, quantity: float, runningBalance: record, sedol: string, settleDate: string, sourceId: string, sourceType: string, status: string, subType: string, symbol: string, transactionDate: string, type: string, valoren: string>>"
    get-transaction-categories: "record<transactionCategory: table<category: string, classification: string, defaultCategoryName: string, defaultHighLevelCategoryName: string, detailCategory: list, highLevelCategoryId: int, highLevelCategoryName: string, id: int, source: string, type: string>>"
    get-transaction-categorization-rules-deprecated: "table<categoryLevelId: int, memId: int, ruleClauses: list<record>, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int>"
    get-transaction-categorization-rules: "record<txnRules: table<categoryLevelId: int, memId: int, ruleClauses: list, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int>>"
    get-transactions-count: "record<transaction: record<TOTAL: record<count: int>>>"
    get-user: "record<user: record<address: record<address1: string, address2: string, address3: string, city: string, country: string, state: string, zip: string>, email: string, id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, segmentName: string>>"
    get-access-tokens: "record<user: record<accessTokens: list<record>>>"
    register-user: "record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>>"
    saml-login: "record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>>"
    get-verification-status: "record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, remainingAttempts: int, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>"
    initiate-matching-or-challenge-deposite-verification: "record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>"
    verify-challenge-deposit: "record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>"
    initiate-account-verification: "record<verifyAccount: record<account: list<record>, transactionCriteria: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-all-accounts" "create-manual-account" "evaluate-address" "get-historical-balances" "delete-account" "get-account" "update-account" "get-api-keys" "generate-api-key" "delete-api-key" "delete-token" "generate-access-token" "get-subscribed-events" "delete-subscribed-event" "create-subscription-event" "update-subscribed-event" "cobrand-login" "cobrand-logout" "get-public-key" "get-subscribed-notification-events" "delete-subscribed-notification-event" "create-subscription-notification-event" "update-subscribed-notification-event" "get-public-encryption-key" "get-data-extracts-events" "get-data-extracts-user-data" "get-holding-summary" "get-networth" "get-transaction-summary" "get-documents" "delete-document" "download-document" "get-holdings" "get-asset-classification-list" "get-holding-type-list" "get-securities" "get-all-provider-accounts" "edit-credentials-or-refresh-provider-account" "get-provider-account-profiles" "delete-provider-account" "get-provider-account" "update-preferences" "get-all-providers" "get-providers-count" "get-provider" "get-statements" "get-transactions" "get-transaction-categories" "create-transaction-category" "update-transaction-category" "get-transaction-categorization-rules-deprecated" "create-or-run-transaction-categorization-rules" "delete-transaction-categorization-rule" "run-transaction-categorization-rule" "update-transaction-categorization-rule" "get-transaction-categorization-rules" "delete-transaction-category" "get-transactions-count" "update-transaction" "get-user" "update-user" "get-access-tokens" "user-logout" "register-user" "saml-login" "unregister" "get-verification-status" "initiate-matching-or-challenge-deposite-verification" "verify-challenge-deposit" "initiate-account-verification" "commands"] | sort) } | get name | first)
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

# Get Accounts
#
# GET /accounts
# Returns: record<account: table<"401kLoan": record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>>
# operationId: getAllAccounts
export def "get-all-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds.
  --container: string # bank/creditCard/investment/insurance/loan/reward/realEstate/otherAssets/otherLiabilities
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefreshNote:fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
  --provider-account-id: string # Comma separated providerAccountIds.
  --request-id: string # The unique identifier that returns contextual data
  --status: string # ACTIVE,INACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: accountId, var: account_id}, {name: container, var: container}, {name: include, var: include}, {name: providerAccountId, var: provider_account_id}, {name: requestId, var: request_id}, {name: status, var: status}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, container: $container, include: $include, provider_account_id: $provider_account_id, request_id: $request_id, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add Manual Account
#
# POST /accounts
# Returns: record<account: table<accountName: string, accountNumber: string, id: int>>
# operationId: createManualAccount
export def "create-manual-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName: string, accountNumber?: string, accountType: string, address?: record, amountDue?: record, balance?: record, dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, memo?: string, nickname?: string, valuationType?: "SYSTEM"|"MANUAL"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Evaluate Address
#
# POST /accounts/evaluateAddress
# Returns: record<address: table<address1: string, address2: string, address3: string, city: string, country: string, sourceType: string, state: string, street: string, type: string, zip: string>, isValidAddress: bool>
# operationId: evaluateAddress
export def "evaluate-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {address1?: string, address2?: string, address3?: string, city?: string, country?: string, sourceType?: string, state?: string, street: string, type?: "HOME"|"BUSINESS"|"POBOX"|"RETAIL"|"OFFICE"|"SMALL_BUSINESS"|"COMMUNICATION"|"PERMANENT"|"STATEMENT_ADDRESS"|"PAYMENT"|"PAYOFF"|"UNKNOWN", zip?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/accounts/evaluateAddress"
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    address: $address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Historical Balances
#
# GET /accounts/historicalBalances
# Returns: record<account: table<historicalBalances: list, id: int>>
# operationId: getHistoricalBalances
export def "get-historical-balances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include-cf: oneof<nothing, bool> # Consider carry forward logic for missing balances
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/historicalBalances"
    query: [{name: accountId, var: account_id}, {name: fromDate, var: from_date}, {name: includeCF, var: include_cf}, {name: interval, var: interval}, {name: skip, var: skip}, {name: toDate, var: to_date}, {name: top, var: top}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, from_date: $from_date, include_cf: $include_cf, interval: $interval, skip: $skip, to_date: $to_date, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Account
#
# DELETE /accounts/{accountId}
# operationId: deleteAccount
export def "delete-account" [
  account_id: int
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
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Account Details
#
# GET /accounts/{accountId}
# Returns: record<account: table<"401kLoan": record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>>
# operationId: getAccount
export def "get-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefreshNote:fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: include, var: include}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account
#
# PUT /accounts/{accountId}
# operationId: updateAccount
export def "update-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName?: string, accountNumber?: string, accountStatus?: "ACTIVE"|"INACTIVE"|"TO_BE_CLOSED"|"CLOSED"|"DELETED", address?: record, amountDue?: record, balance?: record, container?: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", dueDate?: string, ... (6 more fields)}
]: any -> any {
  $in | http-request {
    method: put
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: account, var: account}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    account_id: $account_id, account: $account
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get API Keys
#
# GET /auth/apiKey
# Returns: record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>>
# operationId: getApiKeys
export def "get-api-keys" [
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
    path: "/auth/apiKey"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate API Key
#
# POST /auth/apiKey
# Returns: record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>>
# operationId: generateApiKey
export def "generate-api-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-key: string # Public key uploaded by the customer while generating ApiKey.Endpoints:GET /auth/apiKeyPOST /auth/apiKey
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/auth/apiKey"
    body: {content_type: "application/json", kind: json, fields: [{name: publicKey, var: public_key}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: bearer
  } {
    public_key: $public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete API Key
#
# DELETE /auth/apiKey/{key}
# operationId: deleteApiKey
export def "delete-api-key" [
  key: string
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
    path: "/auth/apiKey/{key}"
    path_params: [{name: key, var: key}]
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Token
#
# DELETE /auth/token
# operationId: deleteToken
export def "delete-token" [
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
    path: "/auth/token"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Generate Access Token
#
# POST /auth/token
# Returns: record<token: record<accessToken: string, expiresIn: int, issuedAt: string>>
# operationId: generateAccessToken
export def "generate-access-token" [
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
    method: post
    path: "/auth/token"
    accept: ["application/json;charset=UTF-8"]
    ok: [201]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Subscribed Events
#
# GET /cobrand/config/notifications/events
# DEPRECATED
# Returns: record<event: table<callbackUrl: string, name: string>>
# operationId: getSubscribedEvents
@deprecated
export def "get-subscribed-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/cobrand/config/notifications/events"
    query: [{name: eventName, var: event_name}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Subscription
#
# DELETE /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: deleteSubscribedEvent
@deprecated
export def "delete-subscribed-event" [
  event_name: string@event-name-completer
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
    path: "/cobrand/config/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe Event
#
# POST /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: createSubscriptionEvent
@deprecated
export def "create-subscription-event" [
  event_name: string@event-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/cobrand/config/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    event_name: $event_name, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Subscription
#
# PUT /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: updateSubscribedEvent
@deprecated
export def "update-subscribed-event" [
  event_name: string@event-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/cobrand/config/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    event_name: $event_name, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cobrand Login
#
# POST /cobrand/login
# Returns: record<applicationId: string, cobrandId: int, locale: string, session: record<cobSession: string>>
# operationId: cobrandLogin
export def "cobrand-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cobrand: record # shape: {cobrandLogin: string, cobrandPassword: string, locale?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/cobrand/login"
    body: {content_type: "application/json", kind: json, fields: [{name: cobrand, var: cobrand}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    cobrand: $cobrand
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cobrand Logout
#
# POST /cobrand/logout
# operationId: cobrandLogout
export def "cobrand-logout" [
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
    method: post
    path: "/cobrand/logout"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Public Key
#
# GET /cobrand/publicKey
# DEPRECATED
# Returns: record<keyAlias: string, keyAsPemString: string>
# operationId: getPublicKey
@deprecated
export def "get-public-key" [
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
    path: "/cobrand/publicKey"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Subscribed Notification Events
#
# GET /configs/notifications/events
# Returns: record<event: table<callbackUrl: string, name: string>>
# operationId: getSubscribedNotificationEvents
export def "get-subscribed-notification-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/configs/notifications/events"
    query: [{name: eventName, var: event_name}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Notification Subscription
#
# DELETE /configs/notifications/events/{eventName}
# operationId: deleteSubscribedNotificationEvent
export def "delete-subscribed-notification-event" [
  event_name: string@event-name-completer
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
    path: "/configs/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    event_name: $event_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe For Notification Event
#
# POST /configs/notifications/events/{eventName}
# operationId: createSubscriptionNotificationEvent
export def "create-subscription-notification-event" [
  event_name: string@event-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/configs/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    event_name: $event_name, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Notification Subscription
#
# PUT /configs/notifications/events/{eventName}
# operationId: updateSubscribedNotificationEvent
export def "update-subscribed-notification-event" [
  event_name: string@event-name-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/configs/notifications/events/{eventName}"
    path_params: [{name: eventName, var: event_name}]
    body: {content_type: "application/json", kind: json, fields: [{name: event, var: event}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    event_name: $event_name, event: $event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Public Key
#
# GET /configs/publicKey
# Returns: record<publicKey: record<alias: string, key: string>>
# operationId: getPublicEncryptionKey
export def "get-public-encryption-key" [
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
    path: "/configs/publicKey"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Events
#
# GET /dataExtracts/events
# Returns: record<event: record<data: record<fromDate: string, toDate: string, userCount: int, userData: list>, info: string>>
# operationId: getDataExtractsEvents
export def "get-data-extracts-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string # Event Name (required)
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ) (required)
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataExtracts/events"
    query: [{name: eventName, var: event_name, required: true}, {name: fromDate, var: from_date, required: true}, {name: toDate, var: to_date, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    event_name: $event_name, from_date: $from_date, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get userData
#
# GET /dataExtracts/userData
# Returns: record<userData: table<account: list, holding: list, providerAccount: list, totalTransactionsCount: int, transaction: list, user: record>>
# operationId: getDataExtractsUserData
export def "get-data-extracts-user-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ) (required)
  --login-name: string # Login Name (required)
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ) (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dataExtracts/userData"
    query: [{name: fromDate, var: from_date, required: true}, {name: loginName, var: login_name, required: true}, {name: toDate, var: to_date, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    from_date: $from_date, login_name: $login_name, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Holding Summary
#
# GET /derived/holdingSummary
# Returns: record<holdingSummary: table<account: list, classificationType: string, classificationValue: string, holding: list, value: record>, link: record<holdings: string>>
# operationId: getHoldingSummary
export def "get-holding-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # Comma separated accountIds
  --classification-type: string # e.g. Country, Sector, etc.
  --include: string # details
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/derived/holdingSummary"
    query: [{name: accountIds, var: account_ids}, {name: classificationType, var: classification_type}, {name: include, var: include}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_ids: $account_ids, classification_type: $classification_type, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Networth Summary
#
# GET /derived/networth
# Returns: record<networth: table<asset: record, date: string, historicalBalances: list, liability: record, networth: record>>
# operationId: getNetworth
export def "get-networth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # comma separated accountIds
  --container: string # bank/creditCard/investment/insurance/loan/realEstate/otherAssets/otherLiabilities
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include: string # details
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/derived/networth"
    query: [{name: accountIds, var: account_ids}, {name: container, var: container}, {name: fromDate, var: from_date}, {name: include, var: include}, {name: interval, var: interval}, {name: skip, var: skip}, {name: toDate, var: to_date}, {name: top, var: top}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_ids: $account_ids, container: $container, from_date: $from_date, include: $include, interval: $interval, skip: $skip, to_date: $to_date, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transaction Summary
#
# GET /derived/transactionSummary
# Returns: record<links: record<transactions: string>, transactionSummary: table<categorySummary: list, categoryType: string, creditTotal: record, debitTotal: record, links: record>>
# operationId: getTransactionSummary
export def "get-transaction-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # comma separated account Ids
  --category-id: string # comma separated categoryIds
  --category-type: string # INCOME, EXPENSE, TRANSFER, UNCATEGORIZE or DEFERRED_COMPENSATION
  --from-date: string # YYYY-MM-DD format
  --group-by: string # CATEGORY_TYPE, HIGH_LEVEL_CATEGORY or CATEGORY (required)
  --include: string # details
  --include-user-category: oneof<nothing, bool> # TRUE/FALSE
  --interval: string # D-daily, W-weekly, M-mothly or Y-yearly
  --to-date: string # YYYY-MM-DD format
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/derived/transactionSummary"
    query: [{name: accountId, var: account_id}, {name: categoryId, var: category_id}, {name: categoryType, var: category_type}, {name: fromDate, var: from_date}, {name: groupBy, var: group_by, required: true}, {name: include, var: include}, {name: includeUserCategory, var: include_user_category}, {name: interval, var: interval}, {name: toDate, var: to_date}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, category_id: $category_id, category_type: $category_type, from_date: $from_date, group_by: $group_by, include: $include, include_user_category: $include_user_category, interval: $interval, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Documents
#
# GET /documents
# Returns: record<document: table<accountID: int, docType: string, formType: string, id: string, lastUpdated: string, name: string, source: string, status: string>>
# operationId: getDocuments
export def "get-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyword: string # The string used to search a document by its name.
  --account-id: string # The unique identifier of an account. Retrieve documents for a given accountId.
  --doc-type: string # Accepts only one of the following valid document types: STMT, TAX, and EBILL.
  --from-date: string # The date from which documents have to be retrieved.
  --to-date: string # The date to which documents have to be retrieved.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/documents"
    query: [{name: Keyword, var: keyword}, {name: accountId, var: account_id}, {name: docType, var: doc_type}, {name: fromDate, var: from_date}, {name: toDate, var: to_date}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    keyword: $keyword, account_id: $account_id, doc_type: $doc_type, from_date: $from_date, to_date: $to_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Document
#
# DELETE /documents/{documentId}
# operationId: deleteDocument
export def "delete-document" [
  document_id: string
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
    path: "/documents/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a Document
#
# GET /documents/{documentId}
# Returns: record<document: table<docContent: string, id: string>>
# operationId: downloadDocument
export def "download-document" [
  document_id: string
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
    path: "/documents/{documentId}"
    path_params: [{name: documentId, var: document_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    document_id: $document_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Holdings
#
# GET /holdings
# Returns: record<holding: table<accountId: int, accruedIncome: record, accruedInterest: record, assetClassification: list, contractQuantity: float, costBasis: record, couponRate: float, createdDate: string, cusipNumber: string, description: string, enrichedDescription: string, exercisedQuantity: float, expirationDate: string, grantDate: string, holdingType: string, id: int, interestRate: float, isShort: bool, isin: string, lastUpdated: string, matchStatus: string, maturityDate: string, optionType: string, price: record, providerAccountId: int, quantity: float, securityStyle: string, securityType: string, sedol: string, spread: record, strikePrice: record, symbol: string, term: string, unvestedQuantity: float, unvestedValue: record, value: record, vestedQuantity: float, vestedSharesExercisable: float, vestedValue: record, vestingDate: string>>
# operationId: getHoldings
export def "get-holdings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --asset-classification-classification-type: string # e.g. Country, Sector, etc.
  --classification-value: string # e.g. US
  --include: string # assetClassification
  --provider-account-id: string # providerAccountId
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/holdings"
    query: [{name: accountId, var: account_id}, {name: "assetClassification.classificationType", var: asset_classification_classification_type}, {name: classificationValue, var: classification_value}, {name: include, var: include}, {name: providerAccountId, var: provider_account_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, asset_classification_classification_type: $asset_classification_classification_type, classification_value: $classification_value, include: $include, provider_account_id: $provider_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Asset Classification List
#
# GET /holdings/assetClassificationList
# Returns: record<assetClassificationList: table<classificationType: string, classificationValue: list>>
# operationId: getAssetClassificationList
export def "get-asset-classification-list" [
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
    path: "/holdings/assetClassificationList"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Holding Type List
#
# GET /holdings/holdingTypeList
# Returns: record<holdingType: list<string>>
# operationId: getHoldingTypeList
export def "get-holding-type-list" [
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
    path: "/holdings/holdingTypeList"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Security Details
#
# GET /holdings/securities
# Returns: record<holding: table<id: string, security: record>>
# operationId: getSecurities
export def "get-securities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --holding-id: string # Comma separated holdingId
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/holdings/securities"
    query: [{name: holdingId, var: holding_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    holding_id: $holding_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Provider Accounts
#
# GET /providerAccounts
# Returns: record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>>
# operationId: getAllProviderAccounts
export def "get-all-provider-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include
  --provider-ids: string # Comma separated providerIds.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providerAccounts"
    query: [{name: include, var: include}, {name: providerIds, var: provider_ids}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    include: $include, provider_ids: $provider_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Account
#
# PUT /providerAccounts
# Returns: record<providerAccount: table<aggregationSource: string, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, providerId: int, requestId: string, status: string>>
# operationId: editCredentialsOrRefreshProviderAccount
export def "edit-credentials-or-refresh-provider-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-ids: string # comma separated providerAccountIds (required)
  --aggregation-source: string@aggregation-source-completer
  --consent-id: int # Consent Id generated for the request through POST Consent.Endpoints:POST Provider AccountPUT Provider Account (format: int64)
  --dataset: list # item shape: {attribute?: list, name?: "BASIC_AGG_DATA"|"ADVANCE_AGG_DATA"|"ACCT_PROFILE"|"DOCUMENT"}
  --dataset-name: list<string>
  field: list # item shape: {id?: string, image?: string, value?: string}
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/providerAccounts"
    query: [{name: providerAccountIds, var: provider_account_ids, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: aggregationSource, var: aggregation_source}, {name: consentId, var: consent_id}, {name: dataset, var: dataset}, {name: datasetName, var: dataset_name}, {name: field, var: field}, {name: preferences, var: preferences}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    provider_account_ids: $provider_account_ids, aggregation_source: $aggregation_source, consent_id: $consent_id, dataset: $dataset, dataset_name: $dataset_name, field: $field, preferences: $preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Profile Details
#
# GET /providerAccounts/profile
# Returns: record<providerAccount: table<id: int, profile: list>>
# operationId: getProviderAccountProfiles
export def "get-provider-account-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-id: string # Comma separated providerAccountIds.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providerAccounts/profile"
    query: [{name: providerAccountId, var: provider_account_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    provider_account_id: $provider_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Provider Account
#
# DELETE /providerAccounts/{providerAccountId}
# operationId: deleteProviderAccount
export def "delete-provider-account" [
  provider_account_id: int
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
    path: "/providerAccounts/{providerAccountId}"
    path_params: [{name: providerAccountId, var: provider_account_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    provider_account_id: $provider_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Provider Account Details
#
# GET /providerAccounts/{providerAccountId}
# Returns: record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>>
# operationId: getProviderAccount
export def "get-provider-account" [
  provider_account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include credentials,questions
  --request-id: string # The unique identifier for the request that returns contextual data
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providerAccounts/{providerAccountId}"
    path_params: [{name: providerAccountId, var: provider_account_id}]
    query: [{name: include, var: include}, {name: requestId, var: request_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    provider_account_id: $provider_account_id, include: $include, request_id: $request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Preferences
#
# PUT /providerAccounts/{providerAccountId}/preferences
# operationId: updatePreferences
export def "update-preferences" [
  provider_account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> any {
  $in | http-request {
    method: put
    path: "/providerAccounts/{providerAccountId}/preferences"
    path_params: [{name: providerAccountId, var: provider_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: preferences, var: preferences}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    provider_account_id: $provider_account_id, preferences: $preferences
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Providers
#
# GET /providers
# Returns: record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, forgetPasswordUrl: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginHelp: string, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>>
# operationId: getAllProviders
export def "get-all-providers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # CHALLENGE_DEPOSIT_VERIFICATION - capability search is deprecated
  --dataset-filter: string # Expression to filter the providers by dataset(s) or dataset attribute(s). The default value will be the dataset or dataset attributes configured as default for the customer.
  --full-account-number-fields: string # Specify to filter the providers with values paymentAccountNumber,unmaskedAccountNumber.
  --institution-id: int # Institution Id for Single site selection (format: int64)
  --name: string # Name in minimum 1 character or routing number.
  --priority: string # Search priority
  --provider-id: string # Max 5 Comma seperated Provider Ids
  --skip: int # skip (Min 0) - This is not applicable along with 'name' parameter. (format: int32)
  --top: int # top (Max 500) - This is not applicable along with 'name' parameter. (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers"
    query: [{name: capability, var: capability}, {name: "dataset$filter", var: dataset_filter}, {name: fullAccountNumberFields, var: full_account_number_fields}, {name: institutionId, var: institution_id}, {name: name, var: name}, {name: priority, var: priority}, {name: providerId, var: provider_id}, {name: skip, var: skip}, {name: top, var: top}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    capability: $capability, dataset_filter: $dataset_filter, full_account_number_fields: $full_account_number_fields, institution_id: $institution_id, name: $name, priority: $priority, provider_id: $provider_id, skip: $skip, top: $top
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Providers Count
#
# GET /providers/count
# Returns: record<provider: record<TOTAL: record<count: int>>>
# operationId: getProvidersCount
export def "get-providers-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # CHALLENGE_DEPOSIT_VERIFICATION - capability search is deprecated
  --dataset-filter: string # Expression to filter the providers by dataset(s) or dataset attribute(s). The default value will be the dataset or dataset attributes configured as default for the customer.
  --full-account-number-fields: string # Specify to filter the providers with values paymentAccountNumber,unmaskedAccountNumber.
  --name: string # Name in minimum 1 character or routing number.
  --priority: string # Search priority
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/providers/count"
    query: [{name: capability, var: capability}, {name: "dataset$filter", var: dataset_filter}, {name: fullAccountNumberFields, var: full_account_number_fields}, {name: name, var: name}, {name: priority, var: priority}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    capability: $capability, dataset_filter: $dataset_filter, full_account_number_fields: $full_account_number_fields, name: $name, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Provider Details
#
# GET /providers/{providerId}
# Returns: record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginForm: list, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>>
# operationId: getProvider
export def "get-provider" [
  provider_id: int
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
    path: "/providers/{providerId}"
    path_params: [{name: providerId, var: provider_id}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    provider_id: $provider_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Statements
#
# GET /statements
# Returns: record<statement: table<accountId: int, amountDue: record, apr: float, billingPeriodEnd: string, billingPeriodStart: string, cashAdvance: record, cashApr: float, dueDate: string, id: int, interestAmount: record, isLatest: bool, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, loanBalance: record, minimumPayment: record, newCharges: record, principalAmount: record, statementDate: string>>
# operationId: getStatements
export def "get-statements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --container: string # creditCard/loan/insurance
  --from-date: string # from date for statement retrieval (YYYY-MM-DD)
  --is-latest: string # isLatest (true/false)
  --status: string # ACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/statements"
    query: [{name: accountId, var: account_id}, {name: container, var: container}, {name: fromDate, var: from_date}, {name: isLatest, var: is_latest}, {name: status, var: status}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, container: $container, from_date: $from_date, is_latest: $is_latest, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transactions
#
# GET /transactions
# Returns: record<transaction: table<CONTAINER: string, accountId: int, amount: record, baseType: string, category: string, categoryId: int, categorySource: string, categoryType: string, checkNumber: string, commission: record, createdDate: string, cusipNumber: string, date: string, description: record, detailCategoryId: int, highLevelCategoryId: int, holdingDescription: string, id: int, interest: record, isManual: bool, isin: string, lastUpdated: string, memo: string, merchant: record, parentCategoryId: int, postDate: string, price: record, principal: record, quantity: float, runningBalance: record, sedol: string, settleDate: string, sourceId: string, sourceType: string, status: string, subType: string, symbol: string, transactionDate: string, type: string, valoren: string>>
# operationId: getTransactions
export def "get-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds
  --base-type: string # DEBIT/CREDIT
  --category-id: string # Comma separated categoryIds
  --category-type: string # Transaction Category Type(UNCATEGORIZE, INCOME, TRANSFER, EXPENSE or DEFERRED_COMPENSATION)
  --container: string # bank/creditCard/investment/insurance/loan
  --detail-category-id: string # Comma separated detailCategoryIds
  --from-date: string # Transaction from date(YYYY-MM-DD)
  --high-level-category-id: string # Comma separated highLevelCategoryIds
  --keyword: string # Transaction search text
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # Transaction end date (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
  --type: string # Transaction Type(SELL,SWEEP, etc.) for bank/creditCard/investment
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions"
    query: [{name: accountId, var: account_id}, {name: baseType, var: base_type}, {name: categoryId, var: category_id}, {name: categoryType, var: category_type}, {name: container, var: container}, {name: detailCategoryId, var: detail_category_id}, {name: fromDate, var: from_date}, {name: highLevelCategoryId, var: high_level_category_id}, {name: keyword, var: keyword}, {name: skip, var: skip}, {name: toDate, var: to_date}, {name: top, var: top}, {name: type, var: type}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, base_type: $base_type, category_id: $category_id, category_type: $category_type, container: $container, detail_category_id: $detail_category_id, from_date: $from_date, high_level_category_id: $high_level_category_id, keyword: $keyword, skip: $skip, to_date: $to_date, top: $top, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transaction Category List
#
# GET /transactions/categories
# Returns: record<transactionCategory: table<category: string, classification: string, defaultCategoryName: string, defaultHighLevelCategoryName: string, detailCategory: list, highLevelCategoryId: int, highLevelCategoryName: string, id: int, source: string, type: string>>
# operationId: getTransactionCategories
export def "get-transaction-categories" [
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
    path: "/transactions/categories"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Category
#
# POST /transactions/categories
# operationId: createTransactionCategory
export def "create-transaction-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-name: string
  parent_category_id: int # format: int32
]: any -> any {
  $in | http-request {
    method: post
    path: "/transactions/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: categoryName, var: category_name}, {name: parentCategoryId, var: parent_category_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    category_name: $category_name, parent_category_id: $parent_category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Category
#
# PUT /transactions/categories
# operationId: updateTransactionCategory
export def "update-transaction-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-name: string
  --high-level-category-name: string
  id: int # format: int64
  source: string@source-completer
]: any -> any {
  $in | http-request {
    method: put
    path: "/transactions/categories"
    body: {content_type: "application/json", kind: json, fields: [{name: categoryName, var: category_name}, {name: highLevelCategoryName, var: high_level_category_name}, {name: id, var: id}, {name: source, var: source}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    category_name: $category_name, high_level_category_name: $high_level_category_name, id: $id, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/rules
# DEPRECATED
# Returns: table<categoryLevelId: int, memId: int, ruleClauses: list<record>, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int>
# operationId: getTransactionCategorizationRulesDeprecated
@deprecated
export def "get-transaction-categorization-rules-deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/categories/rules"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Run Transaction Categorization Rule
#
# POST /transactions/categories/rules
# operationId: createOrRunTransactionCategorizationRules
export def "create-or-run-transaction-categorization-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # To run rules, pass action=run. Only value run is supported
  --rule-param: string # rules(JSON format) to categorize the transactions
]: nothing -> any {
  http-request {
    method: post
    path: "/transactions/categories/rules"
    query: [{name: action, var: action}, {name: ruleParam, var: rule_param}]
    accept: ["application/json"]
    ok: [201, 204]
    auth: bearer
  } {
    action: $action, rule_param: $rule_param
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Transaction Categorization Rule
#
# DELETE /transactions/categories/rules/{ruleId}
# operationId: deleteTransactionCategorizationRule
export def "delete-transaction-categorization-rule" [
  rule_id: int
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
    path: "/transactions/categories/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run Transaction Categorization Rule
#
# POST /transactions/categories/rules/{ruleId}
# operationId: runTransactionCategorizationRule
export def "run-transaction-categorization-rule" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # required, default: run
]: nothing -> any {
  http-request {
    method: post
    path: "/transactions/categories/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    query: [{name: action, var: action, required: true, default: run}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id, action: $action
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Transaction Categorization Rule
#
# PUT /transactions/categories/rules/{ruleId}
# operationId: updateTransactionCategorizationRule
export def "update-transaction-categorization-rule" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rule: record # shape: {categoryId: int, priority?: int, ruleClause: list, source?: "SYSTEM"|"USER"}
]: any -> any {
  $in | http-request {
    method: put
    path: "/transactions/categories/rules/{ruleId}"
    path_params: [{name: ruleId, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: rule, var: rule}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    rule_id: $rule_id, rule: $rule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/txnRules
# Returns: record<txnRules: table<categoryLevelId: int, memId: int, ruleClauses: list, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int>>
# operationId: getTransactionCategorizationRules
export def "get-transaction-categorization-rules" [
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
    path: "/transactions/categories/txnRules"
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Category
#
# DELETE /transactions/categories/{categoryId}
# operationId: deleteTransactionCategory
export def "delete-transaction-category" [
  category_id: int
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
    path: "/transactions/categories/{categoryId}"
    path_params: [{name: categoryId, var: category_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    category_id: $category_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Transactions Count
#
# GET /transactions/count
# Returns: record<transaction: record<TOTAL: record<count: int>>>
# operationId: getTransactionsCount
export def "get-transactions-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds
  --base-type: string # DEBIT/CREDIT
  --category-id: string # Comma separated categoryIds
  --category-type: string # Transaction Category Type(UNCATEGORIZE, INCOME, TRANSFER, EXPENSE or DEFERRED_COMPENSATION)
  --container: string # bank/creditCard/investment/insurance/loan
  --detail-category-id: string # Comma separated detailCategoryIds
  --from-date: string # Transaction from date(YYYY-MM-DD)
  --high-level-category-id: string # Comma separated highLevelCategoryIds
  --keyword: string # Transaction search text
  --to-date: string # Transaction end date (YYYY-MM-DD)
  --type: string # Transaction Type(SELL,SWEEP, etc.)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/transactions/count"
    query: [{name: accountId, var: account_id}, {name: baseType, var: base_type}, {name: categoryId, var: category_id}, {name: categoryType, var: category_type}, {name: container, var: container}, {name: detailCategoryId, var: detail_category_id}, {name: fromDate, var: from_date}, {name: highLevelCategoryId, var: high_level_category_id}, {name: keyword, var: keyword}, {name: toDate, var: to_date}, {name: type, var: type}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, base_type: $base_type, category_id: $category_id, category_type: $category_type, container: $container, detail_category_id: $detail_category_id, from_date: $from_date, high_level_category_id: $high_level_category_id, keyword: $keyword, to_date: $to_date, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Transaction
#
# PUT /transactions/{transactionId}
# operationId: updateTransaction
export def "update-transaction" [
  transaction_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: record # shape: {categoryId: int, categorySource: "SYSTEM"|"USER", container: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", description?: record, memo?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/transactions/{transactionId}"
    path_params: [{name: transactionId, var: transaction_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: transaction, var: transaction}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    transaction_id: $transaction_id, transaction: $transaction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get User Details
#
# GET /user
# Returns: record<user: record<address: record<address1: string, address2: string, address3: string, city: string, country: string, state: string, zip: string>, email: string, id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, segmentName: string>>
# operationId: getUser
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
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update User Details
#
# PUT /user
# operationId: updateUser
export def "update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, name?: record, preferences?: record, segmentName?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/user"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Access Tokens
#
# GET /user/accessTokens
# Returns: record<user: record<accessTokens: list<record>>>
# operationId: getAccessTokens
export def "get-access-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-ids: string # appIds (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user/accessTokens"
    query: [{name: appIds, var: app_ids, required: true}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    app_ids: $app_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# User Logout
#
# POST /user/logout
# operationId: userLogout
export def "user-logout" [
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
    method: post
    path: "/user/logout"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register User
#
# POST /user/register
# Returns: record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>>
# operationId: registerUser
export def "register-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, loginName: string, name?: record, preferences?: record, segmentName?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/user/register"
    body: {content_type: "application/json", kind: json, fields: [{name: user, var: user}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Saml Login
#
# POST /user/samlLogin
# Returns: record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>>
# operationId: samlLogin
export def "saml-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issuer: string # issuer (required)
  --saml-response: string # samlResponse (required)
  --source: string # source
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/user/samlLogin"
    query: [{name: issuer, var: issuer, required: true}, {name: samlResponse, var: saml_response, required: true}, {name: source, var: source}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    issuer: $issuer, saml_response: $saml_response, source: $source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete User
#
# DELETE /user/unregister
# operationId: unregister
export def "unregister" [
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
    path: "/user/unregister"
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Verification Status
#
# GET /verification
# Returns: record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, remainingAttempts: int, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>
# operationId: getVerificationStatus
export def "get-verification-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --provider-account-id: string # Comma separated providerAccountId
  --verification-type: string # verificationType
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/verification"
    query: [{name: accountId, var: account_id}, {name: providerAccountId, var: provider_account_id}, {name: verificationType, var: verification_type}]
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, provider_account_id: $provider_account_id, verification_type: $verification_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiaite Matching Service and Challenge Deposit
#
# POST /verification
# Returns: record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>
# operationId: initiateMatchingOrChallengeDepositeVerification
export def "initiate-matching-or-challenge-deposite-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verification"
    body: {content_type: "application/json", kind: json, fields: [{name: verification, var: verification}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    verification: $verification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Challenge Deposit
#
# PUT /verification
# Returns: record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>>
# operationId: verifyChallengeDeposit
export def "verify-challenge-deposit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, transaction: list, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/verification"
    body: {content_type: "application/json", kind: json, fields: [{name: verification, var: verification}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    verification: $verification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify Accounts Using Transactions
#
# POST /verifyAccount/{providerAccountId}
# Returns: record<verifyAccount: record<account: list<record>, transactionCriteria: list<record>>>
# operationId: initiateAccountVerification
export def "initiate-account-verification" [
  provider_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # format: int64
  --container: string@container-completer
  transaction_criteria: list # item shape: {amount: float, baseType?: "CREDIT"|"DEBIT", date: string, dateVariance?: string, keyword?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/verifyAccount/{providerAccountId}"
    path_params: [{name: providerAccountId, var: provider_account_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountId, var: account_id}, {name: container, var: container}, {name: transactionCriteria, var: transaction_criteria}]}
    accept: ["application/json;charset=UTF-8"]
    ok: [200]
    auth: bearer
  } {
    provider_account_id: $provider_account_id, account_id: $account_id, container: $container, transaction_criteria: $transaction_criteria
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
