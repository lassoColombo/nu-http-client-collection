# Auto-generated client for PayRun.IO v22.23.10.42
# Source: https://api.apis.guru/v2/specs/payrun.io/22.23.10.42/openapi.json
# Auth: --token flag or $env.PAYRUN_IO_TOKEN

const CLIENT = {
  base_url: "https://api.test.payrun.io"
  token_env_var: "PAYRUN_IO_TOKEN"
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

def base-url-completer [] { ["https://api.test.payrun.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-employer: "record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>"
    patch-employer: "record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>"
    put-employer: "record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>"
    get-cis-line-type-from-employer: "record<CisLineType: record<Description: string, LineType: string, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, TaxTreatment: string>>"
    put-cis-line-type-into-employer: "record<CisLineType: record<Description: string, LineType: string, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, TaxTreatment: string>>"
    get-tag-from-cis-line-type: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-cis-line-type-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-cis-line-type: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-line-types-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-cis-line-type-into-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-cis-line-types-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-cis-line-type-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-transaction-from-employer: "record<CisTransaction: record<CisMessageType: string, EmployerCore: record<\"@href\": string, \"@rel\": string, \"@title\": string>, RequestData: string, ResponseData: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>"
    get-cis-transactions-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-dps-message-from-employer: "record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>"
    patch-dps-message: "record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>"
    put-dps-message: "record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>"
    get-dps-messages-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-dps-message: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-employee-from-employer: "record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>"
    patch-employee: "record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>"
    put-employee-into-employer: "record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>"
    get-ae-assessment-from-employee: "record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>>"
    put-new-ae-assessment: "record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>>"
    get-ae-assessments-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-ae-assessment: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-commentaries-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-commentary-from-employee: "record<Commentary: record<Created: string, Detail: string, Employee: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PayRun: record<\"@href\": string, \"@rel\": string, \"@title\": string>>>"
    get-journal-lines-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-instruction-from-employee: "record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>"
    patch-pay-instruction: "record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>"
    put-pay-instruction: "record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>"
    get-tag-from-pay-instruction: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-pay-instruction-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-pay-instruction: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-instructions-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-pay-instruction: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pay-instructions-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-pay-instruction-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-line-from-employee: "record<PayLine: record<Calculator: string, Description: string, Generated: string, PayCode: string, PayCodeType: string, PayRunSequence: int, PaymentDate: string, TaxPeriod: int, TaxYear: int, Value: float>>"
    get-tag-from-pay-line: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-pay-line-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-pay-line: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-lines-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-lines-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-pay-line-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-runs-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employee-revision-by-number: "record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>"
    get-employee-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employee-revision-summaries: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employee-secret: "record<EmployeeSecret: record<Created: string, Name: string, Value: string>>"
    put-employee-secret: "record<EmployeeSecret: record<Created: string, Name: string, Value: string>>"
    get-employee-secrets: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-employee-secret: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-tag-from-employee: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-employee-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tag-from-employee-revision: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-employee: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tags-from-employee-revision: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employee-by-effective-date: "record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>"
    get-employees-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-employee-into-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-employee-summaries-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employees-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-employee-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employees-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employee-summaries-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-holiday-scheme-from-employer: "record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>"
    patch-holiday-scheme: "record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>"
    put-holiday-scheme-into-employer: "record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>"
    get-holiday-scheme-revision-by-number: "record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>"
    get-holiday-scheme-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-holiday-scheme: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-holiday-scheme-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tag-from-holiday-scheme-revision: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-holiday-scheme: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tags-from-holiday-scheme-revision: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-holiday-scheme-by-effective-date: "record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>"
    get-holiday-schemes-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-holiday-scheme-into-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-holiday-schemes-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-holiday-scheme-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-holiday-schemes-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-journal-instruction-from-employer: "record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>"
    put-journal-instruction: "record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>"
    get-journal-instructions-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-journal-instruction: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-journal-line-from-employer: "record<JournalLine: record<Credit: float, Debit: float, Description: string, Employee: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Generated: string, Grouping: string, LedgerTarget: string, NomCode: string, PayFrequency: string, PayRun: record<\"@href\": string, \"@rel\": string, \"@title\": string>, SubContractor: record<\"@href\": string, \"@rel\": string, \"@title\": string>, SubNomCode: string, TaxPeriod: int, TaxYear: int>>"
    get-tag-from-journal-line: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-journal-line-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-journal-line: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-journal-lines-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-journal-lines-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-journal-line-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-nominal-code-from-employer: "record<NominalCode: record<Description: string, Key: string>>"
    put-nominal-code: "record<NominalCode: record<Description: string, Key: string>>"
    get-pay-codes-from-nominal-code: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-nominal-codes-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-nominal-code: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pay-code-from-employer: "record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>"
    patch-pay-code: "record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>"
    put-pay-code: "record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>"
    get-pay-code-revision-by-number: "record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>"
    get-pay-code-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-pay-code: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-pay-code-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-pay-code: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-code-by-effective-date: "record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<\"@href\": string, \"@rel\": string, \"@title\": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>"
    get-pay-codes-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-pay-code: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pay-codes-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-pay-code-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-codes-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-schedule-from-employer: "record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>>"
    put-pay-schedule: "record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>>"
    get-employees-from-pay-schedule: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employees-from-pay-schedule-on-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-run-from-pay-schedule: "record<PayRun: record<Executed: string, IsSupplementary: bool, PayFrequency: string, PaySchedule: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PaymentDate: string, PeriodEnd: string, PeriodStart: string, ProceedingPayRun: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Sequence: int, TaxPeriod: int, TaxYear: int>>"
    get-ae-assessments-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-commentaries-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-commentary-from-pay-run-by-employee: "record<Commentary: record<Created: string, Detail: string, Employee: record<\"@href\": string, \"@rel\": string, \"@title\": string>, PayRun: record<\"@href\": string, \"@rel\": string, \"@title\": string>>>"
    get-employees-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-journal-lines-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-lines-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-report-lines-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-pay-run: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-pay-run-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-pay-run: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-runs-from-pay-schedule: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-runs-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-pay-run-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-pay-schedule: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-pay-schedule-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-pay-schedule: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pay-schedules-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-pay-schedule: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pay-schedules-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-pay-schedule-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pension-from-employer: "record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>"
    patch-pension: "record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>"
    put-pension-into-employer: "record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>"
    get-pension-revision-by-number: "record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>"
    get-pension-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-pension-by-effective-date: "record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>"
    get-pensions-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-pension-into-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pensions-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-report-line-from-employer: "record<ReportLine: record<Description: string, Generated: string, TaxMonth: int, TaxYear: int, Value: float>>"
    get-report-lines-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-reporting-instruction-from-employer: "record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>>"
    put-reporting-instruction: "record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>>"
    get-reporting-instructions-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-reporting-instruction: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-employer-revision-by-number: "record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>"
    get-employer-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employer-revision-summaries: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-rti-transaction-from-employer: "record<RtiTransactionBase: record<EmployerCore: record<\"@href\": string, \"@rel\": string, \"@title\": string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>"
    get-rti-transaction-summary-from-employer: "record<RtiTransactionBase: record<EmployerCore: record<\"@href\": string, \"@rel\": string, \"@title\": string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>"
    get-tag-from-rti-transaction: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-rti-transaction-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-rti-transaction: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-rti-transactions-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-rti-transaction-summaries-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-rti-transactions-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-rti-transaction-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employer-secret: "record<EmployerSecret: record<Created: string, Name: string, Value: string>>"
    put-employer-secret: "record<EmployerSecret: record<Created: string, Name: string, Value: string>>"
    get-employer-secrets: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-employer-secret: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-sub-contractor-from-employer: "record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>"
    patch-sub-contractor: "record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>"
    put-sub-contractor-into-employer: "record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>"
    get-cis-instruction-from-sub-contractor: "record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>"
    patch-cis-instruction: "record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>"
    put-cis-instruction-into-sub-contractor: "record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>"
    get-tag-from-cis-instruction: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-cis-instruction-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-cis-instruction: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-instructions-from-sub-contractor: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-cis-instruction-into-sub-contractor: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-cis-instructions-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-cis-instruction-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-line-from-sub-contractor: "record<CisLine: record<CisDeduction: float, CisLineType: string, Description: string, Generated: string, GrossPay: float, NominalCodeKey: string, PayFrequency: string, TaxMonth: int, TaxPeriod: int, TaxTreatment: string, TaxYear: int, UOM: string, UnitRate: float, Units: float, VAT: float>>"
    get-tag-from-cis-line: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-cis-line-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-cis-line: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-lines-from-sub-contractor: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-cis-lines-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-cis-line-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-journal-lines-from-sub-contractor: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-sub-contractor-revision-by-number: "record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>"
    get-sub-contractor-revisions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-sub-contractor: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-sub-contractor-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tag-from-sub-contractor-revision: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-sub-contractor: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tags-from-sub-contractor-revision: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-sub-contractor-by-effective-date: "record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>"
    get-sub-contractors-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-sub-contractor-into-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-sub-contractors-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-sub-contractor-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-sub-contractors-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-employer: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-employer-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tag-from-employer-revision: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-employer: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tags-from-employer-revision: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-third-party-transaction: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-third-party-transaction-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-third-party-transaction: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-third-party-transactions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-third-party-transactions-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-third-party-transaction-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employer-by-effective-date: "record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>"
    get-employers: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-employer: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-employer-summaries: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employers-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-employer-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employers-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-employer-summaries-by-effective-date: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-health-check: "record<HealthCheck: record<Info: string, Version: string>>"
    get-batch-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-batch-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-batch-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-cis-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-cis-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-cis-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-dps-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-dps-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-dps-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-employer-jobs: "binary"
    get-pay-run-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-pay-run-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-pay-run-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-rti-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-rti-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-rti-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-third-party-jobs: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-new-third-party-job: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-third-party-job-info: "record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>"
    get-journal-instruction-template: "record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>"
    put-journal-instruction-template: "record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>"
    get-journal-instruction-templates: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-journal-instruction-template: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-permission: "record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>"
    patch-permission: "record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>"
    put-permission: "record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>"
    get-tag-from-permission: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-permission-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-permission: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-permissions: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-permission: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-all-permissions-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-permission-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-query-response: "binary"
    get-active-pay-instructions-report-output: "binary"
    get-aoe-liability-report-ouput: "binary"
    get-dps-message-report-output: "binary"
    get-employer-summary-report-ouput: "binary"
    get-gross-to-net-report-output: "binary"
    get-holiday-balance-report-output: "binary"
    get-journal-report-ouput: "binary"
    get-last-pay-date-report-ouput: "binary"
    get-net-pay-report-output: "binary"
    get-next-pay-period-dates-report-output: "binary"
    get-p11-summary-report-output: "binary"
    get-p32-net-report-output: "binary"
    get-p32-summary-net-report-output: "binary"
    get-p45-report-output: "binary"
    get-p60-report-output: "binary"
    get-papdis-report-ouput: "binary"
    get-pass-report-ouput: "binary"
    get-pay-dashboard-payslip-report-ouput: "binary"
    get-payslip3-report-output: "binary"
    get-pension-liability-report-output: "binary"
    get-report-definition-from-application: "record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>>"
    put-report-definition: "record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>>"
    get-report-output: "binary"
    get-report-definitions-from-application: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-report-definition: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-schemas: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-schema: "binary"
    get-application-secrets: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-application-secret: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-template-model: "binary"
    get-templates: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-transform-definition-from-application: "record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>>"
    put-transform-definition: "record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>>"
    get-transform-definitions-from-application: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-transform-definition: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-user: "record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>"
    patch-user: "record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>"
    put-user: "record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>"
    get-user-permissions: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-tag-from-user: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    put-user-tag: "record<Tag: record<Created: string, TaggedItem: record<\"@href\": string, \"@rel\": string, \"@title\": string>, Text: string>>"
    get-tags-from-user: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-users: "record<LinkCollection: record<Links: record<Link: list>>>"
    post-user: "record<Link: record<\"@href\": string, \"@rel\": string, \"@title\": string>>"
    get-all-users-with-tag: "record<LinkCollection: record<Links: record<Link: list>>>"
    get-all-user-tags: "record<LinkCollection: record<Links: record<Link: list>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-employer" "get-employer" "patch-employer" "put-employer" "delete-cis-line-type" "get-cis-line-type-from-employer" "put-cis-line-type-into-employer" "delete-cis-line-type-tag" "get-tag-from-cis-line-type" "put-cis-line-type-tag" "get-tags-from-cis-line-type" "get-cis-line-types-from-employer" "post-cis-line-type-into-employer" "get-cis-line-types-with-tag" "get-all-cis-line-type-tags" "delete-cis-transaction" "get-cis-transaction-from-employer" "get-cis-transactions-from-employer" "delete-dps-message" "get-dps-message-from-employer" "patch-dps-message" "put-dps-message" "get-dps-messages-from-employer" "post-dps-message" "delete-employee" "get-employee-from-employer" "patch-employee" "put-employee-into-employer" "delete-ae-assessment" "get-ae-assessment-from-employee" "put-new-ae-assessment" "get-ae-assessments-from-employee" "post-new-ae-assessment" "get-commentaries-from-employee" "get-commentary-from-employee" "get-journal-lines-from-employee" "delete-pay-instruction" "get-pay-instruction-from-employee" "patch-pay-instruction" "put-pay-instruction" "delete-pay-instruction-tag" "get-tag-from-pay-instruction" "put-pay-instruction-tag" "get-tags-from-pay-instruction" "get-pay-instructions-from-employee" "post-pay-instruction" "get-pay-instructions-with-tag" "get-all-pay-instruction-tags" "get-pay-line-from-employee" "delete-pay-line-tag" "get-tag-from-pay-line" "put-pay-line-tag" "get-tags-from-pay-line" "get-pay-lines-from-employee" "get-pay-lines-with-tag" "get-all-pay-line-tags" "get-pay-runs-from-employee" "delete-employee-revision-by-number" "get-employee-revision-by-number" "get-employee-revision-summary-by-number" "get-employee-revisions" "get-employee-revision-summaries" "delete-employee-secret" "get-employee-secret" "put-employee-secret" "get-employee-secrets" "post-employee-secret" "get-employee-summary-from-employer" "delete-employee-tag" "get-tag-from-employee" "put-employee-tag" "get-tag-from-employee-revision" "get-tags-from-employee" "get-tags-from-employee-revision" "delete-employee-revision" "get-employee-by-effective-date" "get-employee-summary-by-effective-date" "get-employees-from-employer" "post-employee-into-employer" "get-employee-summaries-from-employer" "get-employees-with-tag" "get-all-employee-tags" "get-employees-by-effective-date" "get-employee-summaries-by-effective-date" "delete-holiday-scheme" "get-holiday-scheme-from-employer" "patch-holiday-scheme" "put-holiday-scheme-into-employer" "delete-holiday-scheme-revision-by-number" "get-holiday-scheme-revision-by-number" "get-holiday-scheme-revisions" "delete-holiday-scheme-tag" "get-tag-from-holiday-scheme" "put-holiday-scheme-tag" "get-tag-from-holiday-scheme-revision" "get-tags-from-holiday-scheme" "get-tags-from-holiday-scheme-revision" "delete-holiday-scheme-revision" "get-holiday-scheme-by-effective-date" "get-holiday-schemes-from-employer" "post-holiday-scheme-into-employer" "get-holiday-schemes-with-tag" "get-all-holiday-scheme-tags" "get-holiday-schemes-by-effective-date" "delete-journal-instruction" "get-journal-instruction-from-employer" "put-journal-instruction" "get-journal-instructions-from-employer" "post-journal-instruction" "get-journal-line-from-employer" "delete-journal-line-tag" "get-tag-from-journal-line" "put-journal-line-tag" "get-tags-from-journal-line" "get-journal-lines-from-employer" "get-all-journal-lines-with-tag" "get-all-journal-line-tags" "delete-nominal-code" "get-nominal-code-from-employer" "put-nominal-code" "get-pay-codes-from-nominal-code" "get-nominal-codes-from-employer" "post-nominal-code" "delete-pay-code" "get-pay-code-from-employer" "patch-pay-code" "put-pay-code" "delete-pay-code-revision-by-number" "get-pay-code-revision-by-number" "get-pay-code-revisions" "delete-pay-code-tag" "get-tag-from-pay-code" "put-pay-code-tag" "get-tags-from-pay-code" "delete-pay-code-revision" "get-pay-code-by-effective-date" "get-pay-codes-from-employer" "post-pay-code" "get-pay-codes-with-tag" "get-all-pay-code-tags" "get-pay-codes-by-effective-date" "delete-pay-schedule" "get-pay-schedule-from-employer" "put-pay-schedule" "get-employees-from-pay-schedule" "get-employees-from-pay-schedule-on-effective-date" "delete-pay-run" "get-pay-run-from-pay-schedule" "get-ae-assessments-from-pay-run" "get-commentaries-from-pay-run" "delete-pay-run-employee" "get-commentary-from-pay-run-by-employee" "get-employees-from-pay-run" "get-journal-lines-from-pay-run" "get-pay-lines-from-pay-run" "get-report-lines-from-pay-run" "delete-pay-run-tag" "get-tag-from-pay-run" "put-pay-run-tag" "get-tags-from-pay-run" "get-pay-runs-from-pay-schedule" "get-pay-runs-with-tag" "get-all-pay-run-tags" "delete-pay-schedule-tag" "get-tag-from-pay-schedule" "put-pay-schedule-tag" "get-tags-from-pay-schedule" "get-pay-schedules-from-employer" "post-pay-schedule" "get-pay-schedules-with-tag" "get-all-pay-schedule-tags" "delete-pension" "get-pension-from-employer" "patch-pension" "put-pension-into-employer" "delete-pension-revision-by-number" "get-pension-revision-by-number" "get-pension-revisions" "delete-pension-revision" "get-pension-by-effective-date" "get-pensions-from-employer" "post-pension-into-employer" "get-pensions-by-effective-date" "get-report-line-from-employer" "get-report-lines-from-employer" "delete-reporting-instruction" "get-reporting-instruction-from-employer" "put-reporting-instruction" "get-reporting-instructions-from-employer" "post-reporting-instruction" "delete-employer-revision-by-number" "get-employer-revision-by-number" "get-employer-revision-summary-by-number" "get-employer-revisions" "get-employer-revision-summaries" "delete-rti-transaction" "get-rti-transaction-from-employer" "get-rti-transaction-summary-from-employer" "delete-rti-transaction-tag" "get-tag-from-rti-transaction" "put-rti-transaction-tag" "get-tags-from-rti-transaction" "get-rti-transactions-from-employer" "get-rti-transaction-summaries-from-employer" "get-rti-transactions-with-tag" "get-all-rti-transaction-tags" "delete-employer-secret" "get-employer-secret" "put-employer-secret" "get-employer-secrets" "post-employer-secret" "delete-sub-contractor" "get-sub-contractor-from-employer" "patch-sub-contractor" "put-sub-contractor-into-employer" "delete-cis-instruction" "get-cis-instruction-from-sub-contractor" "patch-cis-instruction" "put-cis-instruction-into-sub-contractor" "delete-cis-instruction-tag" "get-tag-from-cis-instruction" "put-cis-instruction-tag" "get-tags-from-cis-instruction" "get-cis-instructions-from-sub-contractor" "post-cis-instruction-into-sub-contractor" "get-cis-instructions-with-tag" "get-all-cis-instruction-tags" "delete-cis-line" "get-cis-line-from-sub-contractor" "delete-cis-line-tag" "get-tag-from-cis-line" "put-cis-line-tag" "get-tags-from-cis-line" "get-cis-lines-from-sub-contractor" "get-cis-lines-with-tag" "get-all-cis-line-tags" "get-journal-lines-from-sub-contractor" "delete-sub-contractor-revision-by-number" "get-sub-contractor-revision-by-number" "get-sub-contractor-revisions" "delete-sub-contractor-tag" "get-tag-from-sub-contractor" "put-sub-contractor-tag" "get-tag-from-sub-contractor-revision" "get-tags-from-sub-contractor" "get-tags-from-sub-contractor-revision" "delete-sub-contractor-revision" "get-sub-contractor-by-effective-date" "get-sub-contractors-from-employer" "post-sub-contractor-into-employer" "get-sub-contractors-with-tag" "get-all-sub-contractor-tags" "get-sub-contractors-by-effective-date" "get-employer-summary" "delete-employer-tag" "get-tag-from-employer" "put-employer-tag" "get-tag-from-employer-revision" "get-tags-from-employer" "get-tags-from-employer-revision" "delete-third-party-transaction" "get-third-party-transaction" "delete-third-party-transaction-tag" "get-tag-from-third-party-transaction" "put-third-party-transaction-tag" "get-tags-from-third-party-transaction" "get-third-party-transactions" "get-all-third-party-transactions-with-tag" "get-all-third-party-transaction-tags" "delete-employer-revision" "get-employer-by-effective-date" "get-employer-summary-by-effective-date" "get-employers" "post-employer" "get-employer-summaries" "get-employers-with-tag" "get-all-employer-tags" "get-employers-by-effective-date" "get-employer-summaries-by-effective-date" "get-health-check" "get-batch-jobs" "post-new-batch-job" "delete-batch-job" "get-batch-job-info" "get-batch-job-progress" "get-batch-job-status" "get-cis-jobs" "post-new-cis-job" "delete-cis-job" "get-cis-job-info" "get-cis-job-progress" "get-cis-job-status" "get-dps-jobs" "post-new-dps-job" "delete-dps-job" "get-dps-job-info" "get-dps-job-progress" "get-dps-job-status" "get-employer-jobs" "get-pay-run-jobs" "post-new-pay-run-job" "delete-pay-run-job" "get-pay-run-job-info" "get-pay-run-job-progress" "get-pay-run-job-status" "get-rti-jobs" "post-new-rti-job" "delete-rti-job" "get-rti-job-info" "get-rti-job-progress" "get-rti-job-status" "get-third-party-jobs" "post-new-third-party-job" "delete-third-party-job" "get-third-party-job-info" "get-third-party-job-progress" "get-third-party-job-status" "delete-journal-instruction-template" "get-journal-instruction-template" "put-journal-instruction-template" "get-journal-instruction-templates" "post-journal-instruction-template" "delete-permission" "get-permission" "patch-permission" "put-permission" "delete-permission-tag" "get-tag-from-permission" "put-permission-tag" "get-tags-from-permission" "get-permissions" "post-permission" "get-all-permissions-with-tag" "get-all-permission-tags" "get-query-response" "get-journal-expression-schema" "get-active-pay-instructions-report-output" "get-aoe-liability-report-ouput" "get-dps-message-report-output" "get-employer-summary-report-ouput" "get-gross-to-net-report-output" "get-holiday-balance-report-output" "get-journal-report-ouput" "get-last-pay-date-report-ouput" "get-net-pay-report-output" "get-next-pay-period-dates-report-output" "get-p11-summary-report-output" "get-p32-net-report-output" "get-p32-summary-net-report-output" "get-p45-report-output" "get-p60-report-output" "get-papdis-report-ouput" "get-pass-report-ouput" "get-pay-dashboard-payslip-report-ouput" "get-payslip3-report-output" "get-pension-liability-report-output" "delete-report-definition" "get-report-definition-from-application" "put-report-definition" "get-report-output" "get-report-definitions-from-application" "post-report-definition" "get-schemas" "get-schema" "delete-application-secret" "get-application-secret" "put-application-secret" "get-application-secrets" "post-application-secret" "get-template-model" "get-templates" "delete-transform-definition" "get-transform-definition-from-application" "put-transform-definition" "get-transform-definitions-from-application" "post-transform-definition" "delete-user" "get-user" "patch-user" "put-user" "get-user-permissions" "delete-user-tag" "get-tag-from-user" "put-user-tag" "get-tags-from-user" "get-users" "post-user" "get-all-users-with-tag" "get-all-user-tags" "commands"] | sort) } | get name | first)
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

# Delete an Employer
#
# DELETE /Employer/{EmployerId}
# operationId: DeleteEmployer
export def "delete-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employer
#
# GET /Employer/{EmployerId}
# Returns: record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>
# operationId: GetEmployer
export def "get-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the employer
#
# PATCH /Employer/{EmployerId}
# Returns: record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>
# operationId: PatchEmployer
export def "patch-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employer, var: employer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, employer: $employer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Employer
#
# PUT /Employer/{EmployerId}
# Returns: record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>
# operationId: PutEmployer
export def "put-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employer, var: employer}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, employer: $employer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an CIS line type
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: DeleteCisLineType
export def "delete-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line type from employer
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# Returns: record<CisLineType: record<Description: string, LineType: string, NominalCode: record<"@href": string, "@rel": string, "@title": string>, TaxTreatment: string>>
# operationId: GetCisLineTypeFromEmployer
export def "get-cis-line-type-from-employer" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the CIS line type
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# Returns: record<CisLineType: record<Description: string, LineType: string, NominalCode: record<"@href": string, "@rel": string, "@title": string>, TaxTreatment: string>>
# operationId: PutCisLineTypeIntoEmployer
export def "put-cis-line-type-into-employer" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: CisLineType, var: cis_line_type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, authorization: $authorization, api_version: $api_version, cis_line_type: $cis_line_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete CIS line type tag
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: DeleteCisLineTypeTag
export def "delete-cis-line-type-tag" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line type tag
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromCisLineType
export def "get-tag-from-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert CIS line type tag
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutCisLineTypeTag
export def "put-cis-line-type-tag" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the CIS line type
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromCisLineType
export def "get-tags-from-cis-line-type" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisLineTypeId, var: cis_line_type_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line types from employer.
#
# GET /Employer/{EmployerId}/CisLineTypes
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisLineTypesFromEmployer
export def "get-cis-line-types-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineTypes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CIS line type
#
# POST /Employer/{EmployerId}/CisLineTypes
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostCisLineTypeIntoEmployer
export def "post-cis-line-type-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/CisLineTypes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: CisLineType, var: cis_line_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, cis_line_type: $cis_line_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line types with tag
#
# GET /Employer/{EmployerId}/CisLineTypes/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisLineTypesWithTag
export def "get-cis-line-types-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineTypes/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CIS line type tags
#
# GET /Employer/{EmployerId}/CisLineTypes/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllCisLineTypeTags
export def "get-all-cis-line-type-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisLineTypes/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the CIS transaction
#
# DELETE /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: DeleteCisTransaction
export def "delete-cis-transaction" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/CisTransaction/{CisTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisTransactionId, var: cis_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_transaction_id: $cis_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the CIS transaction
#
# GET /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# Returns: record<CisTransaction: record<CisMessageType: string, EmployerCore: record<"@href": string, "@rel": string, "@title": string>, RequestData: string, ResponseData: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>
# operationId: GetCisTransactionFromEmployer
export def "get-cis-transaction-from-employer" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisTransaction/{CisTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: CisTransactionId, var: cis_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, cis_transaction_id: $cis_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CIS transactions for the employer
#
# GET /Employer/{EmployerId}/CisTransactions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisTransactionsFromEmployer
export def "get-cis-transactions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/CisTransactions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the DPS message
#
# DELETE /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: DeleteDpsMessage
export def "delete-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/DpsMessage/{DpsMessageId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: DpsMessageId, var: dps_message_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, dps_message_id: $dps_message_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the DPS message
#
# GET /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# Returns: record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>
# operationId: GetDpsMessageFromEmployer
export def "get-dps-message-from-employer" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/DpsMessage/{DpsMessageId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: DpsMessageId, var: dps_message_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, dps_message_id: $dps_message_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the DPS message
#
# PATCH /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# Returns: record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>
# operationId: PatchDpsMessage
export def "patch-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/Employer/{EmployerId}/DpsMessage/{DpsMessageId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: DpsMessageId, var: dps_message_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, dps_message_id: $dps_message_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts the DPS message
#
# PUT /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# Returns: record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>>
# operationId: PutDpsMessage
export def "put-dps-message" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/DpsMessage/{DpsMessageId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: DpsMessageId, var: dps_message_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, dps_message_id: $dps_message_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the DPS messages
#
# GET /Employer/{EmployerId}/DpsMessages
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetDpsMessagesFromEmployer
export def "get-dps-messages-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/DpsMessages"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Posta the DPS message
#
# POST /Employer/{EmployerId}/DpsMessages
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostDpsMessage
export def "post-dps-message" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Employer/{EmployerId}/DpsMessages"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Employee
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: DeleteEmployee
export def "delete-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}
# Returns: record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>
# operationId: GetEmployeeFromEmployer
export def "get-employee-from-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the employee
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}
# Returns: record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>
# operationId: PatchEmployee
export def "patch-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employee, var: employee}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version, employee: $employee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Employee
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}
# Returns: record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>
# operationId: PutEmployeeIntoEmployer
export def "put-employee-into-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employee, var: employee}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version, employee: $employee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete auto enrolment assessment
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: DeleteAEAssessment
export def "delete-ae-assessment" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: AEAssessmentId, var: ae_assessment_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the auto enrolment assessment
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# Returns: record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>>
# operationId: GetAEAssessmentFromEmployee
export def "get-ae-assessment-from-employee" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: AEAssessmentId, var: ae_assessment_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert new auto enrolment assessment
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# Returns: record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>>
# operationId: PutNewAEAssessment
export def "put-new-ae-assessment" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: AEAssessmentId, var: ae_assessment_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: AEAssessment, var: ae_assessment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id, authorization: $authorization, api_version: $api_version, ae_assessment: $ae_assessment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAEAssessmentsFromEmployee
export def "get-ae-assessments-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert new auto enrolment assessment
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewAEAssessment
export def "post-new-ae-assessment" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, ... (6 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: AEAssessment, var: ae_assessment}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version, ae_assessment: $ae_assessment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to all commentaries for the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentaries
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCommentariesFromEmployee
export def "get-commentaries-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Commentaries"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get commentary from employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentary/{CommentaryId}
# Returns: record<Commentary: record<Created: string, Detail: string, Employee: record<"@href": string, "@rel": string, "@title": string>, PayRun: record<"@href": string, "@rel": string, "@title": string>>>
# operationId: GetCommentaryFromEmployee
export def "get-commentary-from-employee" [
  employer_id: string
  employee_id: string
  commentary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Commentary/{CommentaryId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: CommentaryId, var: commentary_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, commentary_id: $commentary_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the journal Lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/JournalLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalLinesFromEmployee
export def "get-journal-lines-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/JournalLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay instruction
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: DeletePayInstruction
export def "delete-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified pay instruction from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# Returns: record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>
# operationId: GetPayInstructionFromEmployee
export def "get-pay-instruction-from-employee" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sparse Update of a Pay Instruction
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# Returns: record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>
# operationId: PatchPayInstruction
export def "patch-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayInstruction, var: pay_instruction}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, authorization: $authorization, api_version: $api_version, pay_instruction: $pay_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Pay Instruction
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# Returns: record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>>
# operationId: PutPayInstruction
export def "put-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayInstruction, var: pay_instruction}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, authorization: $authorization, api_version: $api_version, pay_instruction: $pay_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pay instruction tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: DeletePayInstructionTag
export def "delete-pay-instruction-tag" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay instruction tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPayInstruction
export def "get-tag-from-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert pay instruction tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPayInstructionTag
export def "put-pay-instruction-tag" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the pay instruction
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPayInstruction
export def "get-tags-from-pay-instruction" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayInstructionId, var: pay_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay instructions from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayInstructionsFromEmployee
export def "get-pay-instructions-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Pay Instruction
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostPayInstruction
export def "post-pay-instruction" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayInstruction, var: pay_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version, pay_instruction: $pay_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay instructions with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayInstructionsWithTag
export def "get-pay-instructions-with-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay instruction tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPayInstructionTags
export def "get-all-pay-instruction-tags" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified pay line from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}
# Returns: record<PayLine: record<Calculator: string, Description: string, Generated: string, PayCode: string, PayCodeType: string, PayRunSequence: int, PaymentDate: string, TaxPeriod: int, TaxYear: int, Value: float>>
# operationId: GetPayLineFromEmployee
export def "get-pay-line-from-employee" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayLineId, var: pay_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pay line tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: DeletePayLineTag
export def "delete-pay-line-tag" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayLineId, var: pay_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay line tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPayLine
export def "get-tag-from-pay-line" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayLineId, var: pay_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert pay line tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPayLineTag
export def "put-pay-line-tag" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayLineId, var: pay_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the pay line
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPayLine
export def "get-tags-from-pay-line" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: PayLineId, var: pay_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayLinesFromEmployee
export def "get-pay-lines-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay lines with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayLinesWithTag
export def "get-pay-lines-with-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay line tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPayLineTags
export def "get-all-pay-line-tags" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay runs from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayRuns
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayRunsFromEmployee
export def "get-pay-runs-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/PayRuns"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Employee revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: DeleteEmployeeRevisionByNumber
export def "delete-employee-revision-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employee by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# Returns: record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>
# operationId: GetEmployeeRevisionByNumber
export def "get-employee-revision-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employee summary by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployeeRevisionSummaryByNumber
export def "get-employee-revision-summary-by-number" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee revisions
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeeRevisions
export def "get-employee-revisions" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee revision summaries
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeeRevisionSummaries
export def "get-employee-revision-summaries" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Revisions/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes employee secret
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: DeleteEmployeeSecret
export def "delete-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee secret
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# Returns: record<EmployeeSecret: record<Created: string, Name: string, Value: string>>
# operationId: GetEmployeeSecret
export def "get-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new employee secret
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# Returns: record<EmployeeSecret: record<Created: string, Name: string, Value: string>>
# operationId: PutEmployeeSecret
export def "put-employee-secret" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee secret links
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeeSecrets
export def "get-employee-secrets" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Secrets"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new employee secret
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostEmployeeSecret
export def "post-employee-secret" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Secrets"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee summary from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Summary
# operationId: GetEmployeeSummaryFromEmployer
export def "get-employee-summary-from-employer" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete employee tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: DeleteEmployeeTag
export def "delete-employee-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromEmployee
export def "get-tag-from-employee" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert employee tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutEmployeeTag
export def "put-employee-tag" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee revision tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}/{EffectiveDate}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromEmployeeRevision
export def "get-tag-from-employee-revision" [
  employer_id: string
  employee_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: TagId, var: tag_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromEmployee
export def "get-tags-from-employee" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee revision tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromEmployeeRevision
export def "get-tags-from-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/Tags/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Employee revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: DeleteEmployeeRevision
export def "delete-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# Returns: record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>>
# operationId: GetEmployeeByEffectiveDate
export def "get-employee-by-effective-date" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee summary by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}/Summary
# operationId: GetEmployeeSummaryByEffectiveDate
export def "get-employee-summary-by-effective-date" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EmployeeId, var: employee_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employees from employer.
#
# GET /Employer/{EmployerId}/Employees
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesFromEmployer
export def "get-employees-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Employee
#
# POST /Employer/{EmployerId}/Employees
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostEmployeeIntoEmployer
export def "post-employee-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, ... (41 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/Employees"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employee, var: employee}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, employee: $employee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee summaries from employer.
#
# GET /Employer/{EmployerId}/Employees/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeeSummariesFromEmployer
export def "get-employee-summaries-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees/Summary"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employees with tag
#
# GET /Employer/{EmployerId}/Employees/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesWithTag
export def "get-employees-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employees/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllEmployeeTags
export def "get-all-employee-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employees from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesByEffectiveDate
export def "get-employees-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employee summaries from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeeSummariesByEffectiveDate
export def "get-employee-summaries-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Employees/{EffectiveDate}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an holiday scheme
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: DeleteHolidayScheme
export def "delete-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday scheme from employer
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# Returns: record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>
# operationId: GetHolidaySchemeFromEmployer
export def "get-holiday-scheme-from-employer" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the holiday scheme
#
# PATCH /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# Returns: record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>
# operationId: PatchHolidayScheme
export def "patch-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: HolidayScheme, var: holiday_scheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version, holiday_scheme: $holiday_scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the holiday scheme
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# Returns: record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>
# operationId: PutHolidaySchemeIntoEmployer
export def "put-holiday-scheme-into-employer" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: HolidayScheme, var: holiday_scheme}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version, holiday_scheme: $holiday_scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an HolidayScheme revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: DeleteHolidaySchemeRevisionByNumber
export def "delete-holiday-scheme-revision-by-number" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the holiday scheme revision by revision number
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# Returns: record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>
# operationId: GetHolidaySchemeRevisionByNumber
export def "get-holiday-scheme-revision-by-number" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all holiday scheme revisions
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetHolidaySchemeRevisions
export def "get-holiday-scheme-revisions" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete holiday scheme tag
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: DeleteHolidaySchemeTag
export def "delete-holiday-scheme-tag" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday scheme tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromHolidayScheme
export def "get-tag-from-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert holiday scheme tag
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutHolidaySchemeTag
export def "put-holiday-scheme-tag" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday scheme revision tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}/{EffectiveDate}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromHolidaySchemeRevision
export def "get-tag-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: TagId, var: tag_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the holiday scheme
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromHolidayScheme
export def "get-tags-from-holiday-scheme" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all holiday scheme revision tags
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromHolidaySchemeRevision
export def "get-tags-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an holiday scheme revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: DeleteHolidaySchemeRevision
export def "delete-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday scheme by effective date.
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# Returns: record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>>
# operationId: GetHolidaySchemeByEffectiveDate
export def "get-holiday-scheme-by-effective-date" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: HolidaySchemeId, var: holiday_scheme_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday schemes from employer.
#
# GET /Employer/{EmployerId}/HolidaySchemes
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetHolidaySchemesFromEmployer
export def "get-holiday-schemes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidaySchemes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new holiday scheme
#
# POST /Employer/{EmployerId}/HolidaySchemes
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostHolidaySchemeIntoEmployer
export def "post-holiday-scheme-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/HolidaySchemes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: HolidayScheme, var: holiday_scheme}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, holiday_scheme: $holiday_scheme
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday schemes with tag
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetHolidaySchemesWithTag
export def "get-holiday-schemes-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidaySchemes/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all holiday scheme tags
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllHolidaySchemeTags
export def "get-all-holiday-scheme-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidaySchemes/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get holiday schemes from employer at a given effective date.
#
# GET /Employer/{EmployerId}/HolidaySchemes/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetHolidaySchemesByEffectiveDate
export def "get-holiday-schemes-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/HolidaySchemes/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Journal instruction
#
# DELETE /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstruction
export def "delete-journal-instruction" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified journal instruction from the employer
#
# GET /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# Returns: record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>
# operationId: GetJournalInstructionFromEmployer
export def "get-journal-instruction-from-employer" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Journal Instruction
#
# PUT /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# Returns: record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>
# operationId: PutJournalInstruction
export def "put-journal-instruction" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Journal instructions from the specified employer
#
# GET /Employer/{EmployerId}/JournalInstructions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalInstructionsFromEmployer
export def "get-journal-instructions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalInstructions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Journal Instruction
#
# POST /Employer/{EmployerId}/JournalInstructions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostJournalInstruction
export def "post-journal-instruction" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Employer/{EmployerId}/JournalInstructions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified journal Line from the employer
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}
# Returns: record<JournalLine: record<Credit: float, Debit: float, Description: string, Employee: record<"@href": string, "@rel": string, "@title": string>, Generated: string, Grouping: string, LedgerTarget: string, NomCode: string, PayFrequency: string, PayRun: record<"@href": string, "@rel": string, "@title": string>, SubContractor: record<"@href": string, "@rel": string, "@title": string>, SubNomCode: string, TaxPeriod: int, TaxYear: int>>
# operationId: GetJournalLineFromEmployer
export def "get-journal-line-from-employer" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLine/{JournalLineId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalLineId, var: journal_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_line_id: $journal_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete journal line tag
#
# DELETE /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: DeleteJournalLineTag
export def "delete-journal-line-tag" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalLineId, var: journal_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get journal line tag
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromJournalLine
export def "get-tag-from-journal-line" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalLineId, var: journal_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert journal line tag
#
# PUT /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutJournalLineTag
export def "put-journal-line-tag" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalLineId, var: journal_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags from journal line
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromJournalLine
export def "get-tags-from-journal-line" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLine/{JournalLineId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: JournalLineId, var: journal_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, journal_line_id: $journal_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Journal Lines from the specified employer
#
# GET /Employer/{EmployerId}/JournalLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalLinesFromEmployer
export def "get-journal-lines-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLines"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to tagged journal lines
#
# GET /Employer/{EmployerId}/JournalLines/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllJournalLinesWithTag
export def "get-all-journal-lines-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLines/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all journal line tags
#
# GET /Employer/{EmployerId}/JournalLines/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllJournalLineTags
export def "get-all-journal-line-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/JournalLines/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the nominal codes
#
# DELETE /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: DeleteNominalCode
export def "delete-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/NominalCode/{NominalCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: NominalCodeId, var: nominal_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, nominal_code_id: $nominal_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# Returns: record<NominalCode: record<Description: string, Key: string>>
# operationId: GetNominalCodeFromEmployer
export def "get-nominal-code-from-employer" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/NominalCode/{NominalCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: NominalCodeId, var: nominal_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, nominal_code_id: $nominal_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert nominal code
#
# PUT /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# Returns: record<NominalCode: record<Description: string, Key: string>>
# operationId: PutNominalCode
export def "put-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/NominalCode/{NominalCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: NominalCodeId, var: nominal_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: NominalCode, var: nominal_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, nominal_code_id: $nominal_code_id, authorization: $authorization, api_version: $api_version, nominal_code: $nominal_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay codes by nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}/PayCodes
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayCodesFromNominalCode
export def "get-pay-codes-from-nominal-code" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/NominalCode/{NominalCodeId}/PayCodes"
    path_params: [{name: EmployerId, var: employer_id}, {name: NominalCodeId, var: nominal_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, nominal_code_id: $nominal_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the nominal codes
#
# GET /Employer/{EmployerId}/NominalCodes
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetNominalCodesFromEmployer
export def "get-nominal-codes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/NominalCodes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert nominal code
#
# POST /Employer/{EmployerId}/NominalCodes
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNominalCode
export def "post-nominal-code" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/NominalCodes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: NominalCode, var: nominal_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, nominal_code: $nominal_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay code
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: DeletePayCode
export def "delete-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified pay code from the employer
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}
# Returns: record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<"@href": string, "@rel": string, "@title": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>
# operationId: GetPayCodeFromEmployer
export def "get-pay-code-from-employer" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the pay code
#
# PATCH /Employer/{EmployerId}/PayCode/{PayCodeId}
# Returns: record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<"@href": string, "@rel": string, "@title": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>
# operationId: PatchPayCode
export def "patch-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayCode, var: pay_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version, pay_code: $pay_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a pay code
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}
# Returns: record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<"@href": string, "@rel": string, "@title": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>
# operationId: PutPayCode
export def "put-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayCode, var: pay_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version, pay_code: $pay_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an PayCode revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: DeletePayCodeRevisionByNumber
export def "delete-pay-code-revision-by-number" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay code by revision number
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# Returns: record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<"@href": string, "@rel": string, "@title": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>
# operationId: GetPayCodeRevisionByNumber
export def "get-pay-code-revision-by-number" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all revisions of the Pay Code
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayCodeRevisions
export def "get-pay-code-revisions" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pay code tag
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: DeletePayCodeTag
export def "delete-pay-code-tag" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay code tag
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPayCode
export def "get-tag-from-pay-code" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert pay code tag
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPayCodeTag
export def "put-pay-code-tag" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPayCode
export def "get-tags-from-pay-code" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay code revision
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: DeletePayCodeRevision
export def "delete-pay-code-revision" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets pay code for specified date
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# Returns: record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<"@href": string, "@rel": string, "@title": string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>>
# operationId: GetPayCodeByEffectiveDate
export def "get-pay-code-by-effective-date" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayCodeId, var: pay_code_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_code_id: $pay_code_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay codes from the employer
#
# GET /Employer/{EmployerId}/PayCodes
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayCodesFromEmployer
export def "get-pay-codes-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCodes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new pay code
#
# POST /Employer/{EmployerId}/PayCodes
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostPayCode
export def "post-pay-code" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/PayCodes"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayCode, var: pay_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, pay_code: $pay_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay codes with tag
#
# GET /Employer/{EmployerId}/PayCodes/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayCodesWithTag
export def "get-pay-codes-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCodes/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCodes/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPayCodeTags
export def "get-all-pay-code-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCodes/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all pay codes for specified date
#
# GET /Employer/{EmployerId}/PayCodes/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayCodesByEffectiveDate
export def "get-pay-codes-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PayCodes/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay schedule
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: DeletePaySchedule
export def "delete-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified pay schedule from the employer
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# Returns: record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>>
# operationId: GetPayScheduleFromEmployer
export def "get-pay-schedule-from-employer" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a pay schedule
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# Returns: record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>>
# operationId: PutPaySchedule
export def "put-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PaySchedule, var: pay_schedule}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version, pay_schedule: $pay_schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employees revisions from a pay schedule.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesFromPaySchedule
export def "get-employees-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employees from a pay schedule on effective date.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesFromPayScheduleOnEffectiveDate
export def "get-employees-from-pay-schedule-on-effective-date" [
  employer_id: string
  pay_schedule_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay run
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: DeletePayRun
export def "delete-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay run from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# Returns: record<PayRun: record<Executed: string, IsSupplementary: bool, PayFrequency: string, PaySchedule: record<"@href": string, "@rel": string, "@title": string>, PaymentDate: string, PeriodEnd: string, PeriodStart: string, ProceedingPayRun: record<"@href": string, "@rel": string, "@title": string>, Sequence: int, TaxPeriod: int, TaxYear: int>>
# operationId: GetPayRunFromPaySchedule
export def "get-pay-run-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/AEAssessments
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAEAssessmentsFromPayRun
export def "get-ae-assessments-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/AEAssessments"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to all commentaries for the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Commentaries
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCommentariesFromPayRun
export def "get-commentaries-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Commentaries"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a pay run employee
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}
# operationId: DeletePayRunEmployee
export def "delete-pay-run-employee" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get commentary from payrun by specified employee.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}/Commentary
# Returns: record<Commentary: record<Created: string, Detail: string, Employee: record<"@href": string, "@rel": string, "@title": string>, PayRun: record<"@href": string, "@rel": string, "@title": string>>>
# operationId: GetCommentaryFromPayRunByEmployee
export def "get-commentary-from-pay-run-by-employee" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}/Commentary"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}, {name: EmployeeId, var: employee_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, employee_id: $employee_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employees from the pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employees
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployeesFromPayRun
export def "get-employees-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employees"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the journal Lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/JournalLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalLinesFromPayRun
export def "get-journal-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/JournalLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/PayLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayLinesFromPayRun
export def "get-pay-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/PayLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the report lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/ReportLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetReportLinesFromPayRun
export def "get-report-lines-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/ReportLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pay run tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: DeletePayRunTag
export def "delete-pay-run-tag" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay run tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPayRun
export def "get-tag-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert pay run tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPayRunTag
export def "put-pay-run-tag" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPayRun
export def "get-tags-from-pay-run" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: PayRunId, var: pay_run_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay runs from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayRunsFromPaySchedule
export def "get-pay-runs-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay runs with tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayRunsWithTag
export def "get-pay-runs-with-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPayRunTags
export def "get-all-pay-run-tags" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete pay schedule tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: DeletePayScheduleTag
export def "delete-pay-schedule-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay schedule tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPaySchedule
export def "get-tag-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert pay schedule tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPayScheduleTag
export def "put-pay-schedule-tag" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPaySchedule
export def "get-tags-from-pay-schedule" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: PayScheduleId, var: pay_schedule_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pay schedule from the specified employer
#
# GET /Employer/{EmployerId}/PaySchedules
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPaySchedulesFromEmployer
export def "get-pay-schedules-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedules"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new pay schedule
#
# POST /Employer/{EmployerId}/PaySchedules
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostPaySchedule
export def "post-pay-schedule" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/PaySchedules"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PaySchedule, var: pay_schedule}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, pay_schedule: $pay_schedule
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pay schedule with tag
#
# GET /Employer/{EmployerId}/PaySchedules/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPaySchedulesWithTag
export def "get-pay-schedules-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedules/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedules/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPayScheduleTags
export def "get-all-pay-schedule-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/PaySchedules/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a Pension
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}
# operationId: DeletePension
export def "delete-pension" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Pension/{PensionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pension from employer
#
# GET /Employer/{EmployerId}/Pension/{PensionId}
# Returns: record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>
# operationId: GetPensionFromEmployer
export def "get-pension-from-employer" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pension/{PensionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the pension
#
# PATCH /Employer/{EmployerId}/Pension/{PensionId}
# Returns: record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>
# operationId: PatchPension
export def "patch-pension" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/Pension/{PensionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Pension, var: pension}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, authorization: $authorization, api_version: $api_version, pension: $pension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the Pension
#
# PUT /Employer/{EmployerId}/Pension/{PensionId}
# Returns: record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>
# operationId: PutPensionIntoEmployer
export def "put-pension-into-employer" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/Pension/{PensionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Pension, var: pension}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, authorization: $authorization, api_version: $api_version, pension: $pension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Pension revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: DeletePensionRevisionByNumber
export def "delete-pension-revision-by-number" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the pension by revision number
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# Returns: record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>
# operationId: GetPensionRevisionByNumber
export def "get-pension-revision-by-number" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all pension revisions
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPensionRevisions
export def "get-pension-revisions" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pension/{PensionId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Pension revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: DeletePensionRevision
export def "delete-pension-revision" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pension by effective date.
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# Returns: record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>>
# operationId: GetPensionByEffectiveDate
export def "get-pension-by-effective-date" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: PensionId, var: pension_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, pension_id: $pension_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pensions from employer.
#
# GET /Employer/{EmployerId}/Pensions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPensionsFromEmployer
export def "get-pensions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pensions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Pension
#
# POST /Employer/{EmployerId}/Pensions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostPensionIntoEmployer
export def "post-pension-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ... (13 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/Pensions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Pension, var: pension}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, pension: $pension
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get pensions from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Pensions/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPensionsByEffectiveDate
export def "get-pensions-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Pensions/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified report line from the employer
#
# GET /Employer/{EmployerId}/ReportLine/{ReportLineId}
# Returns: record<ReportLine: record<Description: string, Generated: string, TaxMonth: int, TaxYear: int, Value: float>>
# operationId: GetReportLineFromEmployer
export def "get-report-line-from-employer" [
  employer_id: string
  report_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ReportLine/{ReportLineId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ReportLineId, var: report_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, report_line_id: $report_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the report lines from the specified employer
#
# GET /Employer/{EmployerId}/ReportLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetReportLinesFromEmployer
export def "get-report-lines-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ReportLines"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a reporting instruction
#
# DELETE /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: DeleteReportingInstruction
export def "delete-reporting-instruction" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ReportingInstructionId, var: reporting_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the specified reporting instruction from the employer
#
# GET /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# Returns: record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>>
# operationId: GetReportingInstructionFromEmployer
export def "get-reporting-instruction-from-employer" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ReportingInstructionId, var: reporting_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a reporting Instruction
#
# PUT /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# Returns: record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>>
# operationId: PutReportingInstruction
export def "put-reporting-instruction" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ReportingInstructionId, var: reporting_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReportingInstruction, var: reporting_instruction}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id, authorization: $authorization, api_version: $api_version, reporting_instruction: $reporting_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the reporting instructions from the specified employer
#
# GET /Employer/{EmployerId}/ReportingInstructions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetReportingInstructionsFromEmployer
export def "get-reporting-instructions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ReportingInstructions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Reporting Instruction
#
# POST /Employer/{EmployerId}/ReportingInstructions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostReportingInstruction
export def "post-reporting-instruction" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/ReportingInstructions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReportingInstruction, var: reporting_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, reporting_instruction: $reporting_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Employer revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: DeleteEmployerRevisionByNumber
export def "delete-employer-revision-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employer by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}
# Returns: record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>
# operationId: GetEmployerRevisionByNumber
export def "get-employer-revision-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employer summary by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployerRevisionSummaryByNumber
export def "get-employer-revision-summary-by-number" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Revision/{RevisionNumber}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employer revisions
#
# GET /Employer/{EmployerId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployerRevisions
export def "get-employer-revisions" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employer revision summaries
#
# GET /Employer/{EmployerId}/Revisions/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployerRevisionSummaries
export def "get-employer-revision-summaries" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Revisions/Summary"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the RTI transaction
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: DeleteRtiTransaction
export def "delete-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# Returns: record<RtiTransactionBase: record<EmployerCore: record<"@href": string, "@rel": string, "@title": string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>
# operationId: GetRtiTransactionFromEmployer
export def "get-rti-transaction-from-employer" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the RTI transaction summary
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Summary
# Returns: record<RtiTransactionBase: record<EmployerCore: record<"@href": string, "@rel": string, "@title": string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>>
# operationId: GetRtiTransactionSummaryFromEmployer
export def "get-rti-transaction-summary-from-employer" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete RTI transaction tag
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: DeleteRtiTransactionTag
export def "delete-rti-transaction-tag" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get RTI transaction tag
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromRtiTransaction
export def "get-tag-from-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert RTI transaction tag
#
# PUT /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutRtiTransactionTag
export def "put-rti-transaction-tag" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromRtiTransaction
export def "get-tags-from-rti-transaction" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: RtiTransactionId, var: rti_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all RTI transactions for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetRtiTransactionsFromEmployer
export def "get-rti-transactions-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransactions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all RTI transaction summaries for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetRtiTransactionSummariesFromEmployer
export def "get-rti-transaction-summaries-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransactions/Summary"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get RTI transactions with tag
#
# GET /Employer/{EmployerId}/RtiTransactions/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetRtiTransactionsWithTag
export def "get-rti-transactions-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransactions/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all RTI transaction tags
#
# GET /Employer/{EmployerId}/RtiTransactions/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllRtiTransactionTags
export def "get-all-rti-transaction-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/RtiTransactions/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes employer secret
#
# DELETE /Employer/{EmployerId}/Secret/{SecretId}
# operationId: DeleteEmployerSecret
export def "delete-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer secret
#
# GET /Employer/{EmployerId}/Secret/{SecretId}
# Returns: record<EmployerSecret: record<Created: string, Name: string, Value: string>>
# operationId: GetEmployerSecret
export def "get-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new employer secret
#
# PUT /Employer/{EmployerId}/Secret/{SecretId}
# Returns: record<EmployerSecret: record<Created: string, Name: string, Value: string>>
# operationId: PutEmployerSecret
export def "put-employer-secret" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Secret/{SecretId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employer secret links
#
# GET /Employer/{EmployerId}/Secrets
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployerSecrets
export def "get-employer-secrets" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Secrets"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new employer secret
#
# POST /Employer/{EmployerId}/Secrets
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostEmployerSecret
export def "post-employer-secret" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Employer/{EmployerId}/Secrets"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an sub contractor
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: DeleteSubContractor
export def "delete-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractor from employer
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}
# Returns: record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>
# operationId: GetSubContractorFromEmployer
export def "get-sub-contractor-from-employer" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the sub contractor
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}
# Returns: record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>
# operationId: PatchSubContractor
export def "patch-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubContractor, var: sub_contractor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version, sub_contractor: $sub_contractor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the sub contractor
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}
# Returns: record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>
# operationId: PutSubContractorIntoEmployer
export def "put-sub-contractor-into-employer" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubContractor, var: sub_contractor}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version, sub_contractor: $sub_contractor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a CIS instruction
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: DeleteCisInstruction
export def "delete-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS instruction from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# Returns: record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>
# operationId: GetCisInstructionFromSubContractor
export def "get-cis-instruction-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches the CIS instruction
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# Returns: record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>
# operationId: PatchCisInstruction
export def "patch-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the CIS instruction
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# Returns: record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>>
# operationId: PutCisInstructionIntoSubContractor
export def "put-cis-instruction-into-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: CisInstruction, var: cis_instruction}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, authorization: $authorization, api_version: $api_version, cis_instruction: $cis_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete CIS instruction tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: DeleteCisInstructionTag
export def "delete-cis-instruction-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS instruction tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromCisInstruction
export def "get-tag-from-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert CIS instruction tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutCisInstructionTag
export def "put-cis-instruction-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the CIS instruction
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromCisInstruction
export def "get-tags-from-cis-instruction" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisInstructionId, var: cis_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS instructions from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisInstructionsFromSubContractor
export def "get-cis-instructions-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new CIS instruction
#
# POST /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostCisInstructionIntoSubContractor
export def "post-cis-instruction-into-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: CisInstruction, var: cis_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version, cis_instruction: $cis_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS instructions with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisInstructionsWithTag
export def "get-cis-instructions-with-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CIS instruction tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllCisInstructionTags
export def "get-all-cis-instruction-tags" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a CIS line
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: DeleteCisLine
export def "delete-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# Returns: record<CisLine: record<CisDeduction: float, CisLineType: string, Description: string, Generated: string, GrossPay: float, NominalCodeKey: string, PayFrequency: string, TaxMonth: int, TaxPeriod: int, TaxTreatment: string, TaxYear: int, UOM: string, UnitRate: float, Units: float, VAT: float>>
# operationId: GetCisLineFromSubContractor
export def "get-cis-line-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete CIS line tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: DeleteCisLineTag
export def "delete-cis-line-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS line tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromCisLine
export def "get-tag-from-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert CIS line tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutCisLineTag
export def "put-cis-line-tag" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the CIS line
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromCisLine
export def "get-tags-from-cis-line" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: CisLineId, var: cis_line_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS lines from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisLinesFromSubContractor
export def "get-cis-lines-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get CIS lines with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisLinesWithTag
export def "get-cis-lines-with-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CIS line tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllCisLineTags
export def "get-all-cis-line-tags" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the journal Lines from the specified sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/JournalLines
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalLinesFromSubContractor
export def "get-journal-lines-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/JournalLines"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SubContractor revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: DeleteSubContractorRevisionByNumber
export def "delete-sub-contractor-revision-by-number" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the sub contractor by revision number
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# Returns: record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>
# operationId: GetSubContractorRevisionByNumber
export def "get-sub-contractor-revision-by-number" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: RevisionNumber, var: revision_number}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, revision_number: $revision_number, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sub contractor revisions
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revisions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetSubContractorRevisions
export def "get-sub-contractor-revisions" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Revisions"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete sub contractor tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: DeleteSubContractorTag
export def "delete-sub-contractor-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractor tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromSubContractor
export def "get-tag-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert sub contractor tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutSubContractorTag
export def "put-sub-contractor-tag" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractor revision tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}/{EffectiveDate}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromSubContractorRevision
export def "get-tag-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: TagId, var: tag_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all tags from the sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromSubContractor
export def "get-tags-from-sub-contractor" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sub contractor revision tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromSubContractorRevision
export def "get-tags-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an sub contractor revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: DeleteSubContractorRevision
export def "delete-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractor by effective date.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# Returns: record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>>
# operationId: GetSubContractorByEffectiveDate
export def "get-sub-contractor-by-effective-date" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: SubContractorId, var: sub_contractor_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractors from employer.
#
# GET /Employer/{EmployerId}/SubContractors
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetSubContractorsFromEmployer
export def "get-sub-contractors-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractors"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new sub contractor
#
# POST /Employer/{EmployerId}/SubContractors
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostSubContractorIntoEmployer
export def "post-sub-contractor-into-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", ... (14 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employer/{EmployerId}/SubContractors"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: SubContractor, var: sub_contractor}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version, sub_contractor: $sub_contractor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractors with tag
#
# GET /Employer/{EmployerId}/SubContractors/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetSubContractorsWithTag
export def "get-sub-contractors-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractors/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all sub contractor tags
#
# GET /Employer/{EmployerId}/SubContractors/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllSubContractorTags
export def "get-all-sub-contractor-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractors/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sub contractors from employer at a given effective date.
#
# GET /Employer/{EmployerId}/SubContractors/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetSubContractorsByEffectiveDate
export def "get-sub-contractors-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/SubContractors/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer summary
#
# GET /Employer/{EmployerId}/Summary
# operationId: GetEmployerSummary
export def "get-employer-summary" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Summary"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete employer tag
#
# DELETE /Employer/{EmployerId}/Tag/{TagId}
# operationId: DeleteEmployerTag
export def "delete-employer-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromEmployer
export def "get-tag-from-employer" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert employer tag
#
# PUT /Employer/{EmployerId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutEmployerTag
export def "put-employer-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer revision tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}/{EffectiveDate}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromEmployerRevision
export def "get-tag-from-employer-revision" [
  employer_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Tag/{TagId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employer tags
#
# GET /Employer/{EmployerId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromEmployer
export def "get-tags-from-employer" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employer revision tags
#
# GET /Employer/{EmployerId}/Tags/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromEmployerRevision
export def "get-tags-from-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/Tags/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete third party transaction
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: DeleteThirdPartyTransaction
export def "delete-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: GetThirdPartyTransaction
export def "get-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete third party transaction tag
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: DeleteThirdPartyTransactionTag
export def "delete-third-party-transaction-tag" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get third party transaction tag
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromThirdPartyTransaction
export def "get-tag-from-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# insert third party transaction tag
#
# PUT /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutThirdPartyTransactionTag
export def "put-third-party-transaction-tag" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags from third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromThirdPartyTransaction
export def "get-tags-from-third-party-transaction" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tags"
    path_params: [{name: EmployerId, var: employer_id}, {name: ThirdPartyTransactionId, var: third_party_transaction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all third party transaction links
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetThirdPartyTransactions
export def "get-third-party-transactions" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransactions"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to tagged third party transactions
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllThirdPartyTransactionsWithTag
export def "get-all-third-party-transactions-with-tag" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransactions/Tag/{TagId}"
    path_params: [{name: EmployerId, var: employer_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all third party transaction tags
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllThirdPartyTransactionTags
export def "get-all-third-party-transaction-tags" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/ThirdPartyTransactions/Tags"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an Employer revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/{EffectiveDate}
# operationId: DeleteEmployerRevision
export def "delete-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Employer/{EmployerId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the employer at the specified effective
#
# GET /Employer/{EmployerId}/{EffectiveDate}
# Returns: record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>>
# operationId: GetEmployerByEffectiveDate
export def "get-employer-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/{EffectiveDate}"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer summary by effective date.
#
# GET /Employer/{EmployerId}/{EffectiveDate}/Summary
# operationId: GetEmployerSummaryByEffectiveDate
export def "get-employer-summary-by-effective-date" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Employer/{EmployerId}/{EffectiveDate}/Summary"
    path_params: [{name: EmployerId, var: employer_id}, {name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all employers
#
# GET /Employers
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployers
export def "get-employers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Employer
#
# POST /Employers
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostEmployer
export def "post-employer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, ... (2 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Employers"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Employer, var: employer}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, employer: $employer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer summaries.
#
# GET /Employers/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployerSummaries
export def "get-employer-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers/Summary"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employers with tag
#
# GET /Employers/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployersWithTag
export def "get-employers-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers/Tag/{TagId}"
    path_params: [{name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all employer tags
#
# GET /Employers/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllEmployerTags
export def "get-all-employer-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers/Tags"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all employers at the specified effective date
#
# GET /Employers/{EffectiveDate}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployersByEffectiveDate
export def "get-employers-by-effective-date" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers/{EffectiveDate}"
    path_params: [{name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get employer summaries at a given effective date.
#
# GET /Employers/{EffectiveDate}/Summary
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetEmployerSummariesByEffectiveDate
export def "get-employer-summaries-by-effective-date" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Employers/{EffectiveDate}/Summary"
    path_params: [{name: EffectiveDate, var: effective_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    effective_date: $effective_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get health check status
#
# GET /Healthcheck
# Returns: record<HealthCheck: record<Info: string, Version: string>>
# operationId: GetHealthCheck
export def "get-health-check" [
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
    path: "/Healthcheck"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Batch jobs
#
# GET /Jobs/Batch
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetBatchJobs
export def "get-batch-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Batch"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Batch job
#
# POST /Jobs/Batch
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewBatchJob
export def "post-new-batch-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --batch-job-instruction: record # shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/Batch"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: BatchJobInstruction, var: batch_job_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, batch_job_instruction: $batch_job_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the Batch job
#
# DELETE /Jobs/Batch/{JobId}
# operationId: DeleteBatchJob
export def "delete-batch-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/Batch/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Batch job information
#
# GET /Jobs/Batch/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetBatchJobInfo
export def "get-batch-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Batch/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Batch job progress
#
# GET /Jobs/Batch/{JobId}/Progress
# operationId: GetBatchJobProgress
export def "get-batch-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Batch/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Batch job status
#
# GET /Jobs/Batch/{JobId}/Status
# operationId: GetBatchJobStatus
export def "get-batch-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Batch/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all CIS jobs
#
# GET /Jobs/Cis
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetCisJobs
export def "get-cis-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Cis"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new CIS job
#
# POST /Jobs/Cis
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewCisJob
export def "post-new-cis-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --cis-job-instruction-base: record # shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/Cis"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: CisJobInstructionBase, var: cis_job_instruction_base}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, cis_job_instruction_base: $cis_job_instruction_base
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the CIS job
#
# DELETE /Jobs/Cis/{JobId}
# operationId: DeleteCisJob
export def "delete-cis-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/Cis/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the CIS job information
#
# GET /Jobs/Cis/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetCisJobInfo
export def "get-cis-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Cis/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the CIS job progress
#
# GET /Jobs/Cis/{JobId}/Progress
# operationId: GetCisJobProgress
export def "get-cis-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Cis/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the CIS job status
#
# GET /Jobs/Cis/{JobId}/Status
# operationId: GetCisJobStatus
export def "get-cis-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Cis/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all DPS jobs
#
# GET /Jobs/Dps
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetDpsJobs
export def "get-dps-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Dps"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new DPS job
#
# POST /Jobs/Dps
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewDpsJob
export def "post-new-dps-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --dps-job-instruction: record # shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/Dps"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: DpsJobInstruction, var: dps_job_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, dps_job_instruction: $dps_job_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the DPS job
#
# DELETE /Jobs/Dps/{JobId}
# operationId: DeleteDpsJob
export def "delete-dps-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/Dps/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the DPS job information
#
# GET /Jobs/Dps/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetDpsJobInfo
export def "get-dps-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Dps/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the DPS job progress
#
# GET /Jobs/Dps/{JobId}/Progress
# operationId: GetDpsJobProgress
export def "get-dps-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Dps/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the DPS job status
#
# GET /Jobs/Dps/{JobId}/Status
# operationId: GetDpsJobStatus
export def "get-dps-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Dps/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all jobs relating to the employer.
#
# GET /Jobs/Employer/{EmployerId}
# Returns: binary
# operationId: GetEmployerJobs
export def "get-employer-jobs" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Employer/{EmployerId}"
    path_params: [{name: EmployerId, var: employer_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_id: $employer_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all PayRun jobs
#
# GET /Jobs/PayRuns
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPayRunJobs
export def "get-pay-run-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/PayRuns"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new PayRun job
#
# POST /Jobs/PayRuns
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewPayRunJob
export def "post-new-pay-run-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --pay-run-job-instruction: record # shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/PayRuns"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: PayRunJobInstruction, var: pay_run_job_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, pay_run_job_instruction: $pay_run_job_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the pay run job
#
# DELETE /Jobs/PayRuns/{JobId}
# operationId: DeletePayRunJob
export def "delete-pay-run-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/PayRuns/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the pay run job information
#
# GET /Jobs/PayRuns/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetPayRunJobInfo
export def "get-pay-run-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/PayRuns/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the pay run job progress
#
# GET /Jobs/PayRuns/{JobId}/Progress
# operationId: GetPayRunJobProgress
export def "get-pay-run-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/PayRuns/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the pay run job status
#
# GET /Jobs/PayRuns/{JobId}/Status
# operationId: GetPayRunJobStatus
export def "get-pay-run-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/PayRuns/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all RTI jobs
#
# GET /Jobs/Rti
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetRtiJobs
export def "get-rti-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Rti"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new RTI job
#
# POST /Jobs/Rti
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewRtiJob
export def "post-new-rti-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --rti-job-instruction: record # shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/Rti"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: RtiJobInstruction, var: rti_job_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, rti_job_instruction: $rti_job_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the RTI job
#
# DELETE /Jobs/Rti/{JobId}
# operationId: DeleteRtiJob
export def "delete-rti-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/Rti/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the RTI job information
#
# GET /Jobs/Rti/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetRtiJobInfo
export def "get-rti-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/Rti/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the RTI job progress
#
# GET /Jobs/Rti/{JobId}/Progress
# operationId: GetRtiJobProgress
export def "get-rti-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Rti/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the RTI job status
#
# GET /Jobs/Rti/{JobId}/Status
# operationId: GetRtiJobStatus
export def "get-rti-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/Rti/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Third Party jobs
#
# GET /Jobs/ThirdParty
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetThirdPartyJobs
export def "get-third-party-jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/ThirdParty"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new Third Party job
#
# POST /Jobs/ThirdParty
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostNewThirdPartyJob
export def "post-new-third-party-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --third-party-job-instruction: record # shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Jobs/ThirdParty"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: ThirdPartyJobInstruction, var: third_party_job_instruction}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, third_party_job_instruction: $third_party_job_instruction
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete the Third Party job
#
# DELETE /Jobs/ThirdParty/{JobId}
# operationId: DeleteThirdPartyJob
export def "delete-third-party-job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Jobs/ThirdParty/{JobId}"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Third Party job information
#
# GET /Jobs/ThirdParty/{JobId}/Info
# Returns: record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>>
# operationId: GetThirdPartyJobInfo
export def "get-third-party-job-info" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Jobs/ThirdParty/{JobId}/Info"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Third Party job progress
#
# GET /Jobs/ThirdParty/{JobId}/Progress
# operationId: GetThirdPartyJobProgress
export def "get-third-party-job-progress" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/ThirdParty/{JobId}/Progress"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Third Party job status
#
# GET /Jobs/ThirdParty/{JobId}/Status
# operationId: GetThirdPartyJobStatus
export def "get-third-party-job-status" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Jobs/ThirdParty/{JobId}/Status"
    path_params: [{name: JobId, var: job_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_id: $job_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a Journal instruction template
#
# DELETE /JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstructionTemplate
export def "delete-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Journal instructions template for the application
#
# GET /JournalInstruction/{JournalInstructionId}
# Returns: record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>
# operationId: GetJournalInstructionTemplate
export def "get-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a Journal Instruction template
#
# PUT /JournalInstruction/{JournalInstructionId}
# Returns: record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>>
# operationId: PutJournalInstructionTemplate
export def "put-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/JournalInstruction/{JournalInstructionId}"
    path_params: [{name: JournalInstructionId, var: journal_instruction_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    journal_instruction_id: $journal_instruction_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Journal instructions templates for the application
#
# GET /JournalInstructions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetJournalInstructionTemplates
export def "get-journal-instruction-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/JournalInstructions"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new Journal Instruction template
#
# POST /JournalInstructions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostJournalInstructionTemplate
export def "post-journal-instruction-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/JournalInstructions"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the permission object
#
# DELETE /Permission/{PermissionId}
# operationId: DeletePermission
export def "delete-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Permission/{PermissionId}"
    path_params: [{name: PermissionId, var: permission_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the permission object
#
# GET /Permission/{PermissionId}
# Returns: record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>
# operationId: GetPermission
export def "get-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permission/{PermissionId}"
    path_params: [{name: PermissionId, var: permission_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch permission object
#
# PATCH /Permission/{PermissionId}
# Returns: record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>
# operationId: PatchPermission
export def "patch-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/Permission/{PermissionId}"
    path_params: [{name: PermissionId, var: permission_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts permisson object
#
# PUT /Permission/{PermissionId}
# Returns: record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>>
# operationId: PutPermission
export def "put-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Permission/{PermissionId}"
    path_params: [{name: PermissionId, var: permission_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Permission tag
#
# DELETE /Permission/{PermissionId}/Tag/{TagId}
# operationId: DeletePermissionTag
export def "delete-permission-tag" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Permission/{PermissionId}/Tag/{TagId}"
    path_params: [{name: PermissionId, var: permission_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Permission tag
#
# GET /Permission/{PermissionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromPermission
export def "get-tag-from-permission" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permission/{PermissionId}/Tag/{TagId}"
    path_params: [{name: PermissionId, var: permission_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert Permission tag
#
# PUT /Permission/{PermissionId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutPermissionTag
export def "put-permission-tag" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/Permission/{PermissionId}/Tag/{TagId}"
    path_params: [{name: PermissionId, var: permission_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags from Permission
#
# GET /Permission/{PermissionId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromPermission
export def "get-tags-from-permission" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permission/{PermissionId}/Tags"
    path_params: [{name: PermissionId, var: permission_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    permission_id: $permission_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all permission objects
#
# GET /Permissions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetPermissions
export def "get-permissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permissions"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post permisson object
#
# POST /Permissions
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostPermission
export def "post-permission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Permissions"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to tagged Permissions
#
# GET /Permissions/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPermissionsWithTag
export def "get-all-permissions-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permissions/Tag/{TagId}"
    path_params: [{name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Permission tags
#
# GET /Permissions/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllPermissionTags
export def "get-all-permission-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Permissions/Tags"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the query result
#
# POST /Query
# Returns: binary
# operationId: GetQueryResponse
export def "get-query-response" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --query: record # shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
]: any -> any {
  $in | http-request {
    method: post
    path: "/Query"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: Query, var: query}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the journal expression data schema
#
# GET /ReferenceData/JournalExpressionDataTable
# operationId: GetJournalExpressionSchema
export def "get-journal-expression-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/ReferenceData/JournalExpressionDataTable"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the active pay instructions report
#
# GET /Report/ACTPAYINS/run
# Returns: binary
# operationId: GetActivePayInstructionsReportOutput
export def "get-active-pay-instructions-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --employee-key: string # The employee unique key. E.g. EE001 (required)
  --active-on: string # The active date to consider. E.g 2017-04-05 (format: date)
  --from-date: string # The lower filter date. E.g 2016-04-06 (required, format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --type: string # the data type to filter on. E.g. TaxPayInstruction
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/ACTPAYINS/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: EmployeeKey, var: employee_key, required: true}, {name: ActiveOn, var: active_on}, {name: FromDate, var: from_date, required: true}, {name: ToDate, var: to_date}, {name: Type, var: type}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, employee_key: $employee_key, active_on: $active_on, from_date: $from_date, to_date: $to_date, type: $type, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the AOE liability report
#
# GET /Report/AOELIABILITY/run
# Returns: binary
# operationId: GetAoeLiabilityReportOuput
export def "get-aoe-liability-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/AOELIABILITY/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: TaxPeriod, var: tax_period}, {name: TransformDefinitionKey, var: transform_definition_key}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, tax_period: $tax_period, transform_definition_key: $transform_definition_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the DPS message report
#
# GET /Report/DPSMSG/run
# Returns: binary
# operationId: GetDpsMessageReportOutput
export def "get-dps-message-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --from-date: string # The lower filter date. E.g 2016-04-06 (required, format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --message-types: string # The DPS message types as a CSV list. E.g. P6,P9,SL1,SL2
  --message-statuses: string # The DPS message status as a CSV list. E.g. Retrieved,Processed,Blocked,Ignored
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/DPSMSG/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: FromDate, var: from_date, required: true}, {name: ToDate, var: to_date}, {name: MessageTypes, var: message_types}, {name: MessageStatuses, var: message_statuses}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, from_date: $from_date, to_date: $to_date, message_types: $message_types, message_statuses: $message_statuses, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the employer summary report
#
# GET /Report/EMPSUM/run
# Returns: binary
# operationId: GetEmployerSummaryReportOuput
export def "get-employer-summary-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --context-date: string # The date context for the report. E.g. 2018-04-30 (required, format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/EMPSUM/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: ContextDate, var: context_date, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, context_date: $context_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the gross to net report
#
# GET /Report/GRO2NET/run
# Returns: binary
# operationId: GetGrossToNetReportOutput
export def "get-gross-to-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/GRO2NET/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: TaxPeriod, var: tax_period}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, tax_period: $tax_period, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the holiday balance report
#
# GET /Report/HOLBAL/run
# Returns: binary
# operationId: GetHolidayBalanceReportOutput
export def "get-holiday-balance-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --holiday-year-end: string # The holiday year end for the report. E.g. 2018-12-31 (required, format: date)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/HOLBAL/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: HolidayYearEnd, var: holiday_year_end, required: true}, {name: EmployeeCodes, var: employee_codes}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, holiday_year_end: $holiday_year_end, employee_codes: $employee_codes, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the journal report
#
# GET /Report/JOURNAL/run
# Returns: binary
# operationId: GetJournalReportOuput
export def "get-journal-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-frequency: string # The pay frequency option. E.g. Monthly (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --ledger-target: string # Specific to JOURNAL report, a filter used to select the journal lines for the specified ledger target. E.g. [Default] (required)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/JOURNAL/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayFrequency, var: pay_frequency, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: TaxPeriod, var: tax_period}, {name: LedgerTarget, var: ledger_target, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_frequency: $pay_frequency, tax_year: $tax_year, tax_period: $tax_period, ledger_target: $ledger_target, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the last pay date report
#
# GET /Report/LASTPAYDATE/run
# Returns: binary
# operationId: GetLastPayDateReportOuput
export def "get-last-pay-date-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --employee-key: string # The employee unique key. E.g. EE001 (required)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/LASTPAYDATE/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: EmployeeKey, var: employee_key, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, employee_key: $employee_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the net pay report
#
# GET /Report/NETPAY/run
# Returns: binary
# operationId: GetNetPayReportOutput
export def "get-net-pay-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/NETPAY/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: TaxPeriod, var: tax_period}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, tax_period: $tax_period, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the next pay period report
#
# GET /Report/NEXTPERIOD/run
# Returns: binary
# operationId: GetNextPayPeriodDatesReportOutput
export def "get-next-pay-period-dates-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/NEXTPERIOD/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the P11 summary report
#
# GET /Report/P11SUM/run
# Returns: binary
# operationId: GetP11SummaryReportOutput
export def "get-p11-summary-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/P11SUM/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the P32 report
#
# GET /Report/P32/run
# Returns: binary
# operationId: GetP32NetReportOutput
export def "get-p32-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/P32/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: TaxYear, var: tax_year, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, tax_year: $tax_year, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the P32 summary report
#
# GET /Report/P32SUM/run
# Returns: binary
# operationId: GetP32SummaryNetReportOutput
export def "get-p32-summary-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/P32SUM/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: TaxYear, var: tax_year, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, tax_year: $tax_year, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the P45 report
#
# GET /Report/P45/run
# Returns: binary
# operationId: GetP45ReportOutput
export def "get-p45-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --employee-key: string # The employee unique key. E.g. EE001 (required)
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/P45/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: EmployeeKey, var: employee_key, required: true}, {name: TransformDefinitionKey, var: transform_definition_key}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, employee_key: $employee_key, transform_definition_key: $transform_definition_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the P60 report
#
# GET /Report/P60/run
# Returns: binary
# operationId: GetP60ReportOutput
export def "get-p60-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/P60/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: EmployeeCodes, var: employee_codes}, {name: TransformDefinitionKey, var: transform_definition_key}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, tax_year: $tax_year, employee_codes: $employee_codes, transform_definition_key: $transform_definition_key, start_index: $start_index, max_index: $max_index, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the PAPDIS report
#
# GET /Report/PAPDIS/run
# Returns: binary
# operationId: GetPapdisReportOuput
export def "get-papdis-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001 (required)
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions). (required)
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/PAPDIS/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: PaymentDate, var: payment_date}, {name: PensionKey, var: pension_key, required: true}, {name: MessageFunctionCode, var: message_function_code, required: true}, {name: TransformDefinitionKey, var: transform_definition_key}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, payment_date: $payment_date, pension_key: $pension_key, message_function_code: $message_function_code, transform_definition_key: $transform_definition_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the PASS report
#
# GET /Report/PASS/run
# Returns: binary
# operationId: GetPassReportOuput
export def "get-pass-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001 (required)
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions). (required)
  --intermediary-id: string # Specific to PensionSync PASS report, a unique identifier for the Intermediary who is acting on behalf of the employer. (required)
  --document-id: string # Specific to PensionSync PASS report, a document identifier unique for this document within the Intermediary. (required)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/PASS/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: PaymentDate, var: payment_date}, {name: PensionKey, var: pension_key, required: true}, {name: MessageFunctionCode, var: message_function_code, required: true}, {name: IntermediaryId, var: intermediary_id, required: true}, {name: DocumentId, var: document_id, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, payment_date: $payment_date, pension_key: $pension_key, message_function_code: $message_function_code, intermediary_id: $intermediary_id, document_id: $document_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the Pay Dashboard payslips report
#
# GET /Report/PAYDASHBOARD/run
# Returns: binary
# operationId: GetPayDashboardPayslipReportOuput
export def "get-pay-dashboard-payslip-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --publication-date: string # Specific to the Pay Dashboard report, allows the specification of a future payslip publication date. E.g. 2018-12-31 (required, format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/PAYDASHBOARD/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: EmployeeCodes, var: employee_codes}, {name: TransformDefinitionKey, var: transform_definition_key}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}, {name: PaymentDate, var: payment_date}, {name: PublicationDate, var: publication_date, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, employee_codes: $employee_codes, transform_definition_key: $transform_definition_key, start_index: $start_index, max_index: $max_index, payment_date: $payment_date, publication_date: $publication_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the verbose payslip report
#
# GET /Report/PAYSLIP3/run
# Returns: binary
# operationId: GetPayslip3ReportOutput
export def "get-payslip3-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/PAYSLIP3/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: PayScheduleKey, var: pay_schedule_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: EmployeeCodes, var: employee_codes}, {name: TransformDefinitionKey, var: transform_definition_key}, {name: StartIndex, var: start_index}, {name: MaxIndex, var: max_index}, {name: PaymentDate, var: payment_date}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, pay_schedule_key: $pay_schedule_key, tax_year: $tax_year, employee_codes: $employee_codes, transform_definition_key: $transform_definition_key, start_index: $start_index, max_index: $max_index, payment_date: $payment_date, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the pension liability report
#
# GET /Report/PENLIABILITY/run
# Returns: binary
# operationId: GetPensionLiabilityReportOutput
export def "get-pension-liability-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001 (required)
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (required, format: integer)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001 (required)
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/PENLIABILITY/run"
    query: [{name: EmployerKey, var: employer_key, required: true}, {name: TaxYear, var: tax_year, required: true}, {name: PensionKey, var: pension_key, required: true}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    employer_key: $employer_key, tax_year: $tax_year, pension_key: $pension_key, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a report definition
#
# DELETE /Report/{ReportDefinitionId}
# operationId: DeleteReportDefinition
export def "delete-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Report/{ReportDefinitionId}"
    path_params: [{name: ReportDefinitionId, var: report_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    report_definition_id: $report_definition_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the report definition
#
# GET /Report/{ReportDefinitionId}
# Returns: record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>>
# operationId: GetReportDefinitionFromApplication
export def "get-report-definition-from-application" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Report/{ReportDefinitionId}"
    path_params: [{name: ReportDefinitionId, var: report_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_definition_id: $report_definition_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a report definition
#
# PUT /Report/{ReportDefinitionId}
# Returns: record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>>
# operationId: PutReportDefinition
export def "put-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Report/{ReportDefinitionId}"
    path_params: [{name: ReportDefinitionId, var: report_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReportDefinition, var: report_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_definition_id: $report_definition_id, authorization: $authorization, api_version: $api_version, report_definition: $report_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Runs the specified report definition
#
# GET /Report/{ReportDefinitionId}/run
# Returns: binary
# operationId: GetReportOutput
export def "get-report-output" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Report/{ReportDefinitionId}/run"
    path_params: [{name: ReportDefinitionId, var: report_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    report_definition_id: $report_definition_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all reports
#
# GET /Reports
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetReportDefinitionsFromApplication
export def "get-report-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Reports"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new report definition
#
# POST /Reports
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostReportDefinition
export def "post-report-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Reports"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReportDefinition, var: report_definition}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, report_definition: $report_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all available schemas
#
# GET /Schemas
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetSchemas
export def "get-schemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Schemas"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get XSD schema
#
# GET /Schemas/{DtoDataType}
# Returns: binary
# operationId: GetSchema
export def "get-schema" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Schemas/{DtoDataType}"
    path_params: [{name: DtoDataType, var: dto_data_type}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dto_data_type: $dto_data_type, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes Application secret
#
# DELETE /Secret/{SecretId}
# operationId: DeleteApplicationSecret
export def "delete-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Secret/{SecretId}"
    path_params: [{name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Application secret
#
# GET /Secret/{SecretId}
# operationId: GetApplicationSecret
export def "get-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Secret/{SecretId}"
    path_params: [{name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Application secret
#
# PUT /Secret/{SecretId}
# operationId: PutApplicationSecret
export def "put-application-secret" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: put
    path: "/Secret/{SecretId}"
    path_params: [{name: SecretId, var: secret_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    secret_id: $secret_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Application secret links
#
# GET /Secrets
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetApplicationSecrets
export def "get-application-secrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Secrets"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new Application secret
#
# POST /Secrets
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostApplicationSecret
export def "post-application-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Secrets"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the object template
#
# GET /Template/{DtoDataType}
# Returns: binary
# operationId: GetTemplateModel
export def "get-template-model" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: get
    path: "/Template/{DtoDataType}"
    path_params: [{name: DtoDataType, var: dto_data_type}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    dto_data_type: $dto_data_type, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of all available data object tempaltes
#
# GET /Templates
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTemplates
export def "get-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Templates"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a transform definition
#
# DELETE /Transform/{TransformDefinitionId}
# operationId: DeleteTransformDefinition
export def "delete-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/Transform/{TransformDefinitionId}"
    path_params: [{name: TransformDefinitionId, var: transform_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    transform_definition_id: $transform_definition_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the transform definition
#
# GET /Transform/{TransformDefinitionId}
# Returns: record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>>
# operationId: GetTransformDefinitionFromApplication
export def "get-transform-definition-from-application" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Transform/{TransformDefinitionId}"
    path_params: [{name: TransformDefinitionId, var: transform_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transform_definition_id: $transform_definition_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a transform definition
#
# PUT /Transform/{TransformDefinitionId}
# Returns: record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>>
# operationId: PutTransformDefinition
export def "put-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/Transform/{TransformDefinitionId}"
    path_params: [{name: TransformDefinitionId, var: transform_definition_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformDefinition, var: transform_definition}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    transform_definition_id: $transform_definition_id, authorization: $authorization, api_version: $api_version, transform_definition: $transform_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all transform definitions
#
# GET /Transforms
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTransformDefinitionsFromApplication
export def "get-transform-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Transforms"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new transform definition
#
# POST /Transforms
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostTransformDefinition
export def "post-transform-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/Transforms"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    body: {content_type: "application/json", kind: json, fields: [{name: TransformDefinition, var: transform_definition}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version, transform_definition: $transform_definition
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes the user object
#
# DELETE /User/{UserId}
# operationId: DeleteUser
export def "delete-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/User/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the user object
#
# GET /User/{UserId}
# Returns: record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>
# operationId: GetUser
export def "get-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/User/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch user object
#
# PATCH /User/{UserId}
# Returns: record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>
# operationId: PatchUser
export def "patch-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: patch
    path: "/User/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Puts user object
#
# PUT /User/{UserId}
# Returns: record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>>
# operationId: PutUser
export def "put-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/User/{UserId}"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the user permissions
#
# GET /User/{UserId}/Permissions
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetUserPermissions
export def "get-user-permissions" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/User/{UserId}/Permissions"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete user tag
#
# DELETE /User/{UserId}/Tag/{TagId}
# operationId: DeleteUserTag
export def "delete-user-tag" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> any {
  http-request {
    method: delete
    path: "/User/{UserId}/Tag/{TagId}"
    path_params: [{name: UserId, var: user_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user tag
#
# GET /User/{UserId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: GetTagFromUser
export def "get-tag-from-user" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/User/{UserId}/Tag/{TagId}"
    path_params: [{name: UserId, var: user_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Insert user tag
#
# PUT /User/{UserId}/Tag/{TagId}
# Returns: record<Tag: record<Created: string, TaggedItem: record<"@href": string, "@rel": string, "@title": string>, Text: string>>
# operationId: PutUserTag
export def "put-user-tag" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/User/{UserId}/Tag/{TagId}"
    path_params: [{name: UserId, var: user_id}, {name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags from user
#
# GET /User/{UserId}/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetTagsFromUser
export def "get-tags-from-user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/User/{UserId}/Tags"
    path_params: [{name: UserId, var: user_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all user objects
#
# GET /Users
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetUsers
export def "get-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Users"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post user object
#
# POST /Users
# Returns: record<Link: record<"@href": string, "@rel": string, "@title": string>>
# operationId: PostUser
export def "post-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/Users"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get links to tagged users
#
# GET /Users/Tag/{TagId}
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllUsersWithTag
export def "get-all-users-with-tag" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Users/Tag/{TagId}"
    path_params: [{name: TagId, var: tag_id}]
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_id: $tag_id, authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all user tags
#
# GET /Users/Tags
# Returns: record<LinkCollection: record<Links: record<Link: list>>>
# operationId: GetAllUserTags
export def "get-all-user-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. 'Auto' enables auto complete. (required, format: string, default: Auto)
  --api-version: string # The version of the api to target. Omit or set as 'default' to target the current api version. (required, format: string, default: default)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Users/Tags"
    header: [{name: Authorization, var: authorization, required: true, default: Auto}, {name: Api-Version, var: api_version, required: true, default: default}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    authorization: $authorization, api_version: $api_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
