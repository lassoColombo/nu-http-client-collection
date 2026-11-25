# Auto-generated client for shinobiapi v1
# Source: https://api.apis.guru/v2/specs/hillbillysoftware.com/shinobi/v1/swagger.json
# Auth: --token flag or $env.SHINOBIAPI_TOKEN

const CLIENT = {
  base_url: "https://api.hillbillysoftware.com"
  token_env_var: "SHINOBIAPI_TOKEN"
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

def base-url-completer [] { ["https://api.hillbillysoftware.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    actor-get: "table<Bio: string, BirthYear: string, DeathYear: string, Gender: string, Name: string, PopularityIndex: string, ProfileImage: string>"
    add-actor-post: "record<Status: string>"
    add-tv-show-post: "record<Status: string>"
    aliases-by-id-get: "table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string>"
    aliases-get: "table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string>"
    awardsby-winner-get: "table<Category: string, Nominee: string, Type: string, Winner: string, Year: string>"
    awards-get: "table<Category: string, Nominee: string, Type: string, Winner: string, Year: string>"
    schedule-by-date-get: "table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>"
    calendar-countries-get: "table<Name: string>"
    calendar-networks-get: "table<Country: string, Network: string>"
    calendar-show-seasons-get: "table<Year: string>"
    calendarby-showname-season-get: "table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>"
    calendar-by-show-name-get: "table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>"
    calendar-today-get: "table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>"
    actor-in-shows-get: "table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>"
    cast-by-actor-get: "table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>"
    actors-in-tv-show-get: "table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>"
    crew-by-id-get: "table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>"
    crew-by-person-get: "table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>"
    crewby-showname-get: "table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>"
    crew-get: "table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>"
    episodes-by-id-get: "table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>"
    episodes-by-season-get: "table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>"
    episodes-get: "table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>"
    episodes-last-available-seasonby-name-get: "record<Season: string>"
    episodes-last-available-season-get: "record<Season: string>"
    episodes-season-count-get: "record<Episodes: string, Externals: table<ID: string, Name: string>, Seasons: string, Showname: string>"
    get-imd-bid-get-async: "table<ID: string, ShinobiID: string, Title: string, Type: string>"
    images-get: "table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string>"
    image-search-get: "table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string>"
    magnets-by-date-get-async: "table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>"
    magnets-byimdb-id-get-async: "table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>"
    magnets-movie-by-id-get-async: "table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>"
    tv-showsearch-get: "table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>"
    movie-id-get: "record<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string>"
    movie-search-get-async: "table<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string>"
    music-album-art-get: "record<AlbumID: string, Albumname: string, Art: string>"
    music-cd-covers-get: "table<CoverImage: string, CoverThumbMedium: string, CoverThumbSmall: string, CoverType: string, MusicBrainzID: string>"
    music-by-music-brainz-get: "table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string>"
    music-albums-get: "table<AlbumArt: string, AlbumID: string, ArtistID: string, Bibliography: string, Label: string, Name: string, Releaseyear: string>"
    music-cover-art-get: "record<ArtistID: string, Banner: string, Logo: string, Name: string>"
    music-cover-art-by-name-get: "record<ArtistID: string, Banner: string, Logo: string, Name: string>"
    music-artist-extended-get: "table<Albums: list<record>, ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, Videos: list<record>, WebSite: string>"
    music-get: "table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string>"
    music-lyricsby-album-id-get: "table<AlbumID: string, Artist: string, Lyrics: string, Song: string>"
    music-lyrics-get: "table<AlbumID: string, Artist: string, Lyrics: string, Song: string>"
    music-lyrics-by-song-get: "table<AlbumID: string, Artist: string, Lyrics: string, Song: string>"
    music-tracks-get: "table<AlbumID: string, ArtistID: string, Length: string, TrackName: string, TrackNo: string>"
    musi-videos-get: "table<AlbumID: string, ArtistID: string, Decription: string, Video: string>"
    rating-get: "record<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string>"
    rating-by-name-get: "table<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string>"
    show-status-get: "table<Enddate: string, ID: string, Title: string, YearsOn: string, imdbID: string, status: string, tvdbID: string>"
    tv-show-id-get: "record<EpisodeCount: string, EpisodeRuntime: string, Externals: table<ID: string, Name: string>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string>"
    tv-show-by-name-get: "table<EpisodeCount: string, EpisodeRuntime: string, Externals: list<record>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string>"
    trailersby-id-get: "table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string>"
    trailer-count-by-id-get: "record<Count: int>"
    trailer-count-by-name-get: "record<Count: int>"
    trailer-search-get: "table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["actor-get" "add-actor-post" "add-tv-show-post" "aliases-by-id-get" "aliases-get" "awardsby-winner-get" "awards-get" "schedule-by-date-get" "calendar-countries-get" "calendar-networks-get" "calendar-show-seasons-get" "calendarby-showname-season-get" "calendar-by-show-name-get" "calendar-today-get" "actor-in-shows-get" "cast-by-actor-get" "actors-in-tv-show-get" "crew-by-id-get" "crew-by-person-get" "crewby-showname-get" "crew-get" "episodes-by-id-get" "episodes-by-season-get" "episodes-get" "episodes-last-available-seasonby-name-get" "episodes-last-available-season-get" "episodes-season-count-get" "get-imd-bid-get-async" "images-get" "image-search-get" "magnets-by-date-get-async" "magnets-byimdb-id-get-async" "magnets-movie-by-id-get-async" "tv-showsearch-get" "movie-id-get" "movie-search-get-async" "music-album-art-get" "music-cd-covers-get" "music-by-music-brainz-get" "music-albums-get" "music-cover-art-get" "music-cover-art-by-name-get" "music-artist-extended-get" "music-get" "music-lyricsby-album-id-get" "music-lyrics-get" "music-lyrics-by-song-get" "music-tracks-get" "musi-videos-get" "rating-get" "rating-by-name-get" "show-status-get" "tv-show-id-get" "tv-show-by-name-get" "trailersby-id-get" "trailer-count-by-id-get" "trailer-count-by-name-get" "trailer-search-get" "commands"] | sort) } | get name | first)
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

# Returns data on queried actor/actress. Result set limited to 5 records
#
# GET /Actors/Search/{accesstoken}/{Query}
# Returns: table<Bio: string, BirthYear: string, DeathYear: string, Gender: string, Name: string, PopularityIndex: string, ProfileImage: string>
# operationId: Actor_Get
export def "actor-get" [
  accesstoken: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Actors/Search/{accesstoken}/{Query}"
    path_params: [{name: accesstoken, var: accesstoken}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    accesstoken: $accesstoken, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add new actor or actress to database
#
# POST /AddActor
# Returns: record<Status: string>
# operationId: AddActor_Post
export def "add-actor-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-token: string
  --bio: string
  --birth-year: string
  --death-year: string
  --gender: string
  --name: string
  --popularity-index: string
  --profile-image: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/AddActor"
    body: {content_type: "application/json", kind: json, fields: [{name: AccessToken, var: access_token}, {name: Bio, var: bio}, {name: BirthYear, var: birth_year}, {name: DeathYear, var: death_year}, {name: Gender, var: gender}, {name: Name, var: name}, {name: PopularityIndex, var: popularity_index}, {name: ProfileImage, var: profile_image}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    access_token: $access_token, bio: $bio, birth_year: $birth_year, death_year: $death_year, gender: $gender, name: $name, popularity_index: $popularity_index, profile_image: $profile_image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add new show to database
#
# POST /AddTVShow
# Returns: record<Status: string>
# operationId: AddTVShow_Post
export def "add-tv-show-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-token: string
  --episode-count: string
  --episode-runtime: string
  --genres: string
  --imdb-id: string
  --premier-year: string
  --seasons: string
  --show-image: string
  --show-status: string
  --synopsis: string
  --title: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/AddTVShow"
    body: {content_type: "application/json", kind: json, fields: [{name: AccessToken, var: access_token}, {name: EpisodeCount, var: episode_count}, {name: EpisodeRuntime, var: episode_runtime}, {name: Genres, var: genres}, {name: ImdbID, var: imdb_id}, {name: PremierYear, var: premier_year}, {name: Seasons, var: seasons}, {name: ShowImage, var: show_image}, {name: ShowStatus, var: show_status}, {name: Synopsis, var: synopsis}, {name: Title, var: title}]}
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200, 204]
    auth: bearer
  } {
    access_token: $access_token, episode_count: $episode_count, episode_runtime: $episode_runtime, genres: $genres, imdb_id: $imdb_id, premier_year: $premier_year, seasons: $seasons, show_image: $show_image, show_status: $show_status, synopsis: $synopsis, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get known aliases for Movies or Television shows from passed imdbID
#
# GET /Aliases/ByID/{AccessToken}/{imdbID}
# Returns: table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string>
# operationId: AliasesByID_Get
export def "aliases-by-id-get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Aliases/ByID/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get known aliases for Movies or Television shows
#
# GET /Aliases/ByName/{AccessToken}/{Title}
# Returns: table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string>
# operationId: Aliases_Get
export def "aliases-get" [
  access_token: string
  title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Aliases/ByName/{AccessToken}/{Title}"
    path_params: [{name: AccessToken, var: access_token}, {name: Title, var: title}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all awards by nominiee
#
# GET /Awards/ByWinner/{AccessToken}/{Nominee}
# Returns: table<Category: string, Nominee: string, Type: string, Winner: string, Year: string>
# operationId: AwardsbyWinner_Get
export def "awardsby-winner-get" [
  access_token: string
  nominee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Awards/ByWinner/{AccessToken}/{Nominee}"
    path_params: [{name: AccessToken, var: access_token}, {name: Nominee, var: nominee}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, nominee: $nominee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all awards for requested year
#
# GET /Awards/ByYear/{Year}
# Returns: table<Category: string, Nominee: string, Type: string, Winner: string, Year: string>
# operationId: awards_Get
export def "awards-get" [
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Awards/ByYear/{Year}"
    path_params: [{name: Year, var: year}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets TV Schedule for selected data
#
# GET /Calendar/ByDate/{AccessToken}/{Date}/{Country}
# Returns: table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>
# operationId: ScheduleByDate_Get
export def "schedule-by-date-get" [
  access_token: string
  date: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/ByDate/{AccessToken}/{Date}/{Country}"
    path_params: [{name: AccessToken, var: access_token}, {name: Date, var: date}, {name: Country, var: country}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, date: $date, country: $country
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns list of available countries in calendar database
#
# GET /Calendar/Countries/{AccessToken}
# Returns: table<Name: string>
# operationId: CalendarCountries_Get
export def "calendar-countries-get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Countries/{AccessToken}"
    path_params: [{name: AccessToken, var: access_token}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a list of available networks
#
# GET /Calendar/Networks/{AccessToken}
# Returns: table<Country: string, Network: string>
# operationId: CalendarNetworks_Get
export def "calendar-networks-get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Networks/{AccessToken}"
    path_params: [{name: AccessToken, var: access_token}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns list of seasons available in the calendar for show
#
# GET /Calendar/Seasons/{AccessToken}/{Name}
# Returns: table<Year: string>
# operationId: CalendarShowSeasons_Get
export def "calendar-show-seasons-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Seasons/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Calendar by showname and season
#
# GET /Calendar/Show/Season/{AccessToken}/{Name}/{Season}
# Returns: table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>
# operationId: CalendarbyShownameSeason_Get
export def "calendarby-showname-season-get" [
  access_token: string
  name: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Show/Season/{AccessToken}/{Name}/{Season}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}, {name: Season, var: season}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Will return show schedule for queried showname and year
#
# GET /Calendar/Show/{AccessToken}/{Name}/{Year}
# Returns: table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>
# operationId: CalendarByShowName_Get
export def "calendar-by-show-name-get" [
  access_token: string
  name: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Show/{AccessToken}/{Name}/{Year}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}, {name: Year, var: year}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name, year: $year
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Will return show schedule for today for all countries in database
#
# GET /Calendar/Today/{AccessToken}
# Returns: table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string>
# operationId: CalendarToday_Get
export def "calendar-today-get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Calendar/Today/{AccessToken}"
    path_params: [{name: AccessToken, var: access_token}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all shows queried actor/actress is or has been in
#
# GET /Cast/ActorBySearch/{AccessToken}/{Actor}
# Returns: table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>
# operationId: ActorInShows_Get
export def "actor-in-shows-get" [
  access_token: string
  actor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Cast/ActorBySearch/{AccessToken}/{Actor}"
    path_params: [{name: AccessToken, var: access_token}, {name: Actor, var: actor}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, actor: $actor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns list of show actor is appearing in
#
# GET /Cast/ByActor/{AccessToken}/{Actor}
# Returns: table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>
# operationId: CastByActor_Get
export def "cast-by-actor-get" [
  access_token: string
  actor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Cast/ByActor/{AccessToken}/{Actor}"
    path_params: [{name: AccessToken, var: access_token}, {name: Actor, var: actor}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, actor: $actor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all actors in queried tvshow
#
# GET /Cast/ByTVShow/{accesstoken}/{ShowName}
# Returns: table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string>
# operationId: ActorsInTVShow_Get
export def "actors-in-tv-show-get" [
  accesstoken: string
  show_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Cast/ByTVShow/{accesstoken}/{ShowName}"
    path_params: [{name: accesstoken, var: accesstoken}, {name: ShowName, var: show_name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    accesstoken: $accesstoken, show_name: $show_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get crew list by ID
#
# GET /Crew/ByID/{AccessToken}/{ID}
# Returns: table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>
# operationId: CrewByID_Get
export def "crew-by-id-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Crew/ByID/{AccessToken}/{ID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ID, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of productions searched person is/was involved in.
#
# GET /Crew/ByPerson/{AccessToken}/{PersonName}
# Returns: table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>
# operationId: CrewByPerson_Get
export def "crew-by-person-get" [
  access_token: string
  person_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Crew/ByPerson/{AccessToken}/{PersonName}"
    path_params: [{name: AccessToken, var: access_token}, {name: PersonName, var: person_name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, person_name: $person_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get crew list by showname
#
# GET /Crew/ByShowName/{AccessToken}/{ShowName}
# Returns: table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>
# operationId: CrewbyShowname_Get
export def "crewby-showname-get" [
  access_token: string
  show_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Crew/ByShowName/{AccessToken}/{ShowName}"
    path_params: [{name: AccessToken, var: access_token}, {name: ShowName, var: show_name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, show_name: $show_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns crew for queried show.
#
# GET /Crew/Search/{AccessToken}/{Phrase}
# Returns: table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string>
# operationId: Crew_Get
export def "crew-get" [
  access_token: string
  phrase: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Crew/Search/{AccessToken}/{Phrase}"
    path_params: [{name: AccessToken, var: access_token}, {name: Phrase, var: phrase}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, phrase: $phrase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all episodes for selected ID
#
# GET /Episodes/ByID/{AccessToken}/{ID}
# Returns: table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>
# operationId: EpisodesByID_Get
export def "episodes-by-id-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/ByID/{AccessToken}/{ID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ID, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of episodes for specified imdbID and Season number
#
# GET /Episodes/BySeason/{AccessToken}/{ID}/{Season}
# Returns: table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>
# operationId: EpisodesBySeason_Get
export def "episodes-by-season-get" [
  access_token: string
  id: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/BySeason/{AccessToken}/{ID}/{Season}"
    path_params: [{name: AccessToken, var: access_token}, {name: ID, var: id}, {name: Season, var: season}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, id: $id, season: $season
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all episodes for selected show
#
# GET /Episodes/ByShowName/{AccessToken}/{Showname}
# Returns: table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string>
# operationId: Episodes_Get
export def "episodes-get" [
  access_token: string
  showname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/ByShowName/{AccessToken}/{Showname}"
    path_params: [{name: AccessToken, var: access_token}, {name: Showname, var: showname}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, showname: $showname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets latest season number based on show name
#
# GET /Episodes/LatestSeason/Show/{AccessToken}/{Name}
# Returns: record<Season: string>
# operationId: EpisodesLastAvailableSeasonbyName_Get
export def "episodes-last-available-seasonby-name-get" [
  access_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/LatestSeason/Show/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns last available season number in database, based on passed imdbID
#
# GET /Episodes/LatestSeason/{AccessToken}/{ID}
# Returns: record<Season: string>
# operationId: EpisodesLastAvailableSeason_Get
export def "episodes-last-available-season-get" [
  access_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/LatestSeason/{AccessToken}/{ID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ID, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns number of available seasons and episodes
#
# GET /Episodes/SeasonCount/{AccessToken}/{ID}
# Returns: record<Episodes: string, Externals: table<ID: string, Name: string>, Seasons: string, Showname: string>
# operationId: EpisodesSeasonCount_Get
export def "episodes-season-count-get" [
  access_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Episodes/SeasonCount/{AccessToken}/{ID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ID, var: id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets list of avaiable IMDB ids from Movies and TV Show databases, you can use those to query other end points that need ID's
#
# GET /GetIMDBid/ByID/{AccessToken}/{Query}
# Returns: table<ID: string, ShinobiID: string, Title: string, Type: string>
# operationId: GetIMDBid_GetAsync
export def "get-imd-bid-get-async" [
  access_token: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/GetIMDBid/ByID/{AccessToken}/{Query}"
    path_params: [{name: AccessToken, var: access_token}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get images available for movie/tv show with passed imdbID
#
# GET /Images/ByID/{AccessToken}/{imdbID}
# Returns: table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string>
# operationId: Images_Get
export def "images-get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Images/ByID/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get images available for movie/tv show with passed query
#
# GET /Images/Search/{Accesstoken}/{Query}
# Returns: table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string>
# operationId: ImageSearch_Get
export def "image-search-get" [
  accesstoken: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --strictmatch: oneof<nothing, bool>
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Images/Search/{Accesstoken}/{Query}"
    path_params: [{name: Accesstoken, var: accesstoken}, {name: Query, var: query}]
    query: [{name: Strictmatch, var: strictmatch}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    accesstoken: $accesstoken, query: $query, strictmatch: $strictmatch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets available magnet hashes on passed date (yyyy-mm-dd). Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/ByDate/{AccessToken}/{Date}
# Returns: table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>
# operationId: MagnetsByDate_GetAsync
export def "magnets-by-date-get-async" [
  access_token: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Magnets/ByDate/{AccessToken}/{Date}"
    path_params: [{name: AccessToken, var: access_token}, {name: Date, var: date}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns list of magnet hashes for passed IMDBID. Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/ByIMDB/{AccessToken}/{imdbID}
# Returns: table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>
# operationId: MagnetsByimdbID_GetAsync
export def "magnets-byimdb-id-get-async" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Magnets/ByIMDB/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Try and find magnet links for queried movie. Feature not available on free plan, please donate to be able to use this feature
#
# GET /Magnets/Search/{AccessToken}/{Query}
# Returns: table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>
# operationId: magnetsMovieByID_GetAsync
export def "magnets-movie-by-id-get-async" [
  access_token: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Magnets/Search/{AccessToken}/{Query}"
    path_params: [{name: AccessToken, var: access_token}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns results based on query, Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/TVShow/{AccessToken}/{TVShow}
# Returns: table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string>
# operationId: TVShowsearch_Get
export def "tv-showsearch-get" [
  access_token: string
  tv_show: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Magnets/TVShow/{AccessToken}/{TVShow}"
    path_params: [{name: AccessToken, var: access_token}, {name: TVShow, var: tv_show}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, tv_show: $tv_show
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /Movie/ByID/{accesstoken}/{imdbID}
#
# Returns: record<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string>
# operationId: MovieID_Get
export def "movie-id-get" [
  accesstoken: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/Movie/ByID/{accesstoken}/{imdbID}"
    path_params: [{name: accesstoken, var: accesstoken}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    accesstoken: $accesstoken, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Searches for movies, result set limited to 5 records
#
# GET /Movie/Search/{AccessToken}/{Query}
# Returns: table<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string>
# operationId: MovieSearch_GetAsync
export def "movie-search-get-async" [
  access_token: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Movie/Search/{AccessToken}/{Query}"
    path_params: [{name: AccessToken, var: access_token}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns Albumart for passed AlbumID
#
# GET /Music/Albums/Art/{AccessToken}/{AlbumID}
# Returns: record<AlbumID: string, Albumname: string, Art: string>
# operationId: musicAlbumArt_Get
export def "music-album-art-get" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/Music/Albums/Art/{AccessToken}/{AlbumID}"
    path_params: [{name: AccessToken, var: access_token}, {name: AlbumID, var: album_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets CD art for passed MusicBrainzID
#
# GET /Music/Albums/CoverArt/{AccessToken}/{MBID}
# Returns: table<CoverImage: string, CoverThumbMedium: string, CoverThumbSmall: string, CoverType: string, MusicBrainzID: string>
# operationId: musicCDCovers_Get
export def "music-cd-covers-get" [
  access_token: string
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Albums/CoverArt/{AccessToken}/{MBID}"
    path_params: [{name: AccessToken, var: access_token}, {name: MBID, var: mbid}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, mbid: $mbid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Artist / Band information on MusicBrainzID
#
# GET /Music/Albums/MusicBrainzID/{AccessToken}/{MBID}
# Returns: table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string>
# operationId: MusicByMusicBrainz_Get
export def "music-by-music-brainz-get" [
  access_token: string
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Albums/MusicBrainzID/{AccessToken}/{MBID}"
    path_params: [{name: AccessToken, var: access_token}, {name: MBID, var: mbid}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, mbid: $mbid
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get albums from passed ArtistID
#
# GET /Music/Albums/{AccessToken}/{ArtistID}
# Returns: table<AlbumArt: string, AlbumID: string, ArtistID: string, Bibliography: string, Label: string, Name: string, Releaseyear: string>
# operationId: musicAlbums_Get
export def "music-albums-get" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Albums/{AccessToken}/{ArtistID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ArtistID, var: artist_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, artist_id: $artist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves artist / band Banner and logo based on ArtistID
#
# GET /Music/Artist/Art/ID/{AccessToken}/{ArtistID}
# Returns: record<ArtistID: string, Banner: string, Logo: string, Name: string>
# operationId: musicCoverArt_Get
export def "music-cover-art-get" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/Music/Artist/Art/ID/{AccessToken}/{ArtistID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ArtistID, var: artist_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, artist_id: $artist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves artist / band Banner and logo based on artist or bandname
#
# GET /Music/Artist/Art/Name/{AccessToken}/{Name}
# Returns: record<ArtistID: string, Banner: string, Logo: string, Name: string>
# operationId: musicCoverArtByName_Get
export def "music-cover-art-by-name-get" [
  access_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Artist/Art/Name/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Provides extended information, which includes all known albums and music videos of artist / band
#
# GET /Music/Artist/Extended/{AccessToken}/{Name}
# Returns: table<Albums: list<record>, ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, Videos: list<record>, WebSite: string>
# operationId: musicArtistExtended_Get
export def "music-artist-extended-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Artist/Extended/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get information about passed band name or artist
#
# GET /Music/Artist/{AccessToken}/{Name}
# Returns: table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string>
# operationId: Music_Get
export def "music-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Artist/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns all lyrics for requested AlbumID
#
# GET /Music/Lyrics/AlbumID/{AccessToken}/{AlbumID}
# Returns: table<AlbumID: string, Artist: string, Lyrics: string, Song: string>
# operationId: musicLyricsbyAlbumID_Get
export def "music-lyricsby-album-id-get" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Lyrics/AlbumID/{AccessToken}/{AlbumID}"
    path_params: [{name: AccessToken, var: access_token}, {name: AlbumID, var: album_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get lyrics for band or artist (record set limited to 25)
#
# GET /Music/Lyrics/ByName/{AccessToken}/{Name}
# Returns: table<AlbumID: string, Artist: string, Lyrics: string, Song: string>
# operationId: musicLyrics_Get
export def "music-lyrics-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Lyrics/ByName/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get lyrics on song title
#
# GET /Music/Lyrics/BySong/{AccessToken}/{Song}
# Returns: table<AlbumID: string, Artist: string, Lyrics: string, Song: string>
# operationId: musicLyricsBySong_Get
export def "music-lyrics-by-song-get" [
  access_token: string
  song: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Lyrics/BySong/{AccessToken}/{Song}"
    path_params: [{name: AccessToken, var: access_token}, {name: Song, var: song}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, song: $song
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all tracks from requested album
#
# GET /Music/Tracks/{AccessToken}/{AlbumID}
# Returns: table<AlbumID: string, ArtistID: string, Length: string, TrackName: string, TrackNo: string>
# operationId: musicTracks_Get
export def "music-tracks-get" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Tracks/{AccessToken}/{AlbumID}"
    path_params: [{name: AccessToken, var: access_token}, {name: AlbumID, var: album_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, album_id: $album_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Lists all videos available for this Artist / Band
#
# GET /Music/Videos/{AccessToken}/{ArtistID}
# Returns: table<AlbumID: string, ArtistID: string, Decription: string, Video: string>
# operationId: MusiVideos_Get
export def "musi-videos-get" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Music/Videos/{AccessToken}/{ArtistID}"
    path_params: [{name: AccessToken, var: access_token}, {name: ArtistID, var: artist_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, artist_id: $artist_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns ratings from various resources(IMDB,Rotten Tomatoes, metaCritics, TVMaze etc) of passed IMDBid
#
# GET /Rating/ByID/{AccessToken}/{imdbID}
# Returns: record<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string>
# operationId: Rating_Get
export def "rating-get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/Rating/ByID/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /Rating/ByName/{AccessToken}/{Name}
#
# Returns: table<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string>
# operationId: RatingByName_Get
export def "rating-by-name-get" [
  access_token: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Rating/ByName/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns status of queried show (query can be IMDB, TVDB, or showname)
#
# GET /Status/{AccessToken}/{Query}
# Returns: table<Enddate: string, ID: string, Title: string, YearsOn: string, imdbID: string, status: string, tvdbID: string>
# operationId: ShowStatus_Get
export def "show-status-get" [
  access_token: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Status/{AccessToken}/{Query}"
    path_params: [{name: AccessToken, var: access_token}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns TVShow information based on IMDBid
#
# GET /TV/ByID/{accesstoken}/{imdbID}
# Returns: record<EpisodeCount: string, EpisodeRuntime: string, Externals: table<ID: string, Name: string>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string>
# operationId: TVShowID_Get
export def "tv-show-id-get" [
  accesstoken: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # imdbID of show you want info on (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/TV/ByID/{accesstoken}/{imdbID}"
    path_params: [{name: accesstoken, var: accesstoken}, {name: imdbID, var: imdb_id}]
    query: [{name: id, var: id, required: true}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    accesstoken: $accesstoken, imdb_id: $imdb_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns results based on query, result set limited to 5 records
#
# GET /TV/ByName/{AccessToken}/{Query}
# Returns: table<EpisodeCount: string, EpisodeRuntime: string, Externals: list<record>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string>
# operationId: TVShowByName_Get
export def "tv-show-by-name-get" [
  access_token: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/TV/ByName/{AccessToken}/{Query}"
    path_params: [{name: AccessToken, var: access_token}, {name: Query, var: query}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, query: $query
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get Trailers for passed imdbID
#
# GET /Trailers/ByID/{AccessToken}/{imdbID}
# Returns: table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string>
# operationId: TrailersbyID_Get
export def "trailersby-id-get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Trailers/ByID/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get trailer count for passed ID
#
# GET /Trailers/CountByID/{AccessToken}/{imdbID}
# Returns: record<Count: int>
# operationId: TrailerCountByID_Get
export def "trailer-count-by-id-get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
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
    path: "/Trailers/CountByID/{AccessToken}/{imdbID}"
    path_params: [{name: AccessToken, var: access_token}, {name: imdbID, var: imdb_id}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, imdb_id: $imdb_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get trailer count for passed name (Movie title or TVShow name)
#
# GET /Trailers/CountByName/{AccessToken}/{Name}
# Returns: record<Count: int>
# operationId: TrailerCountByName_Get
export def "trailer-count-by-name-get" [
  access_token: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/Trailers/CountByName/{AccessToken}/{Name}"
    path_params: [{name: AccessToken, var: access_token}, {name: Name, var: name}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets trailers by search phrase (limited to 10 records)
#
# GET /Trailers/Search/{AccessToken}/{Phrase}
# Returns: table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string>
# operationId: TrailerSearch_Get
export def "trailer-search-get" [
  access_token: string
  phrase: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/Trailers/Search/{AccessToken}/{Phrase}"
    path_params: [{name: AccessToken, var: access_token}, {name: Phrase, var: phrase}]
    accept: ["application/json", "text/json", "application/xml", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    access_token: $access_token, phrase: $phrase
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
