# Auto-generated client for Credas API v1
# Source: https://api.apis.guru/v2/specs/credas.co.uk/pi/v1/openapi.json
# Auth: --token flag or $env.CREDAS_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru"
  token_env_var: "CREDAS_API_TOKEN"
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
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def check-type-completer [] { ["0" "1" "2" "3"] }
def document-type-completer [] { ["0" "1" "10" "11" "2" "3" "4" "5" "6" "7" "9"] }
def delivery-method-completer [] { ["0" "1" "2"] }
def check-type-completer-1 [] { ["0" "1" "2" "3" "4" "5" "6" "7" "8"] }
def status-completer [] { ["0" "1" "2" "3"] }
def name-match-routine-completer [] { ["1" "2"] }
def status-completer-1 [] { ["0" "1" "2" "3" "4" "6"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    verify: "record<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>"
    search-company: "record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>>"
    get-company: "record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>>"
    check-credit-status: "record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: table<address1: string, address2: string, address3: string, address4: string, address5: string, amount: string, caseNumber: string, courtName: string, dateEnd: string, dob: string, judgementDate: string, judgementType: int, judgementTypeText: string, name: string, postcode: string>, checkDate: string, companyDirector: table<companyAppointments: list, companyName: string, companyRegNo: string, dateAppointed: string, matchType: int, matchTypeText: string, registeredOffice: string>, hasBeenOverridden: bool, insolvency: table<address: record, aliases: string, assetTotal: string, caseNo: string, caseType: string, court: string, debtTotal: string, description: string, dob: string, name: string, occupation: string, presentationDate: string, previousAddress: record, serviceOffice: string, startDate: string, status: string, telephoneNumber: string, tradingNames: string, type: int, typeText: string>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>"
    add-data-check: "record<id: string, regCode: string>"
    add-id-document-image: "record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string>"
    get-id-document-images: "table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, hiResUrl: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcFacialUrl: string, nfcReadStatus: int, primaryScanId: string, status: int, surname: string, url: string>"
    get-liveness-performed-image: "record<base64Data: string, url: string>"
    get-liveness-image: "record<description: string, id: string, url: string>"
    get-scan-report-pdf: "string"
    add-selfie-image: "record<livenessConfirmed: bool>"
    get-selfie-image: "record<base64Data: string, url: string>"
    add-property-register-check: "record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>"
    get-property-register-check-result: "record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>"
    get-all: "table<id: string, name: string>"
    add-registration: "record<id: string, regCode: string, webJourneyUrl: record<url: string, validUntil: string>>"
    add-instant-registration: "record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string>"
    get-registration-summaries-by-reference-id: "table<Comments: list<record>, DITFDate: string, DITFStatus: int, bankAccountChecks: list<record>, createdByAgencyUserId: string, creditStatusCheck: record<address: record, ccj: list, checkDate: string, companyDirector: list, hasBeenOverridden: bool, insolvency: list, person: record, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list<record>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list<record>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>"
    get-registration-summary-by-reg-code: "record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>"
    get-registration-search: "record<registrationSummaries: table<Comments: list, DITFDate: string, DITFStatus: int, bankAccountChecks: list, createdByAgencyUserId: string, creditStatusCheck: record, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list, idVerification: record, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record, phoneNumber: string, proofOfOwnershipCheck: record, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record, rightToWorkCheck: record, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>, totalCount: int>"
    check-submitted-id-documents: "record<checkCode: int, message: string>"
    get-registration-pdf-export: "string"
    get-api-registrations-id-pdf-export-sections: "string"
    get-share-code-pdf-export: "string"
    get-registration-summary: "record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>"
    get-registration-supported-id-documents: "record<name: string, type: int>"
    get-report-view-by-reference-id: "record<results: table<forename: string, surname: string, url: string, validUntil: string>>"
    get-report-view-by-registration-id: "record<results: table<forename: string, surname: string, url: string, validUntil: string>>"
    get-web-verifications-by-reference-id: "record<results: table<journeyUrl: record>>"
    get-web-verifications-by-registration-id: "record<results: table<journeyUrl: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["verify" "search-company" "get-company" "check-credit-status" "add-data-check" "add-id-document-image" "get-id-document-images" "add-liveness-image" "get-liveness-performed-image" "get-liveness-image" "get-scan-report-pdf" "add-selfie-image" "get-selfie-image" "add-property-register-check" "get-property-register-check-result" "get-all" "add-registration" "add-instant-registration" "get-registration-summaries-by-reference-id" "get-registration-summary-by-reg-code" "get-registration-search" "check-submitted-id-documents" "update-contact-details" "override-check-status" "get-registration-pdf-export" "get-api-registrations-id-pdf-export-sections" "get-share-code-pdf-export" "resend-invitation" "get-registration-settings" "update-registration-settings" "update-registration-status" "get-registration-summary" "get-registration-supported-id-documents" "get-report-view-by-reference-id" "get-report-view-by-registration-id" "get-web-verifications-by-reference-id" "get-web-verifications-by-registration-id" "commands"] | sort) } | get name | first)
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

# Verifies bank account details.
#
# POST /api/bank-accounts/verify
# Returns: record<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>
# operationId: Verify
export def "verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  account_details: record # shape: {accountNumber: string, sortcode: string}
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/bank-accounts/verify"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: accountDetails, var: account_details}, {name: address, var: address}, {name: person, var: person}, {name: regEntryId, var: reg_entry_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, account_details: $account_details, address: $address, person: $person, reg_entry_id: $reg_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Searches for a company based on its Company Number and returns its details.
#
# POST /api/companies
# Returns: record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>>
# operationId: SearchCompany
export def "search-company" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --company-number: string # The company registration number of the company that should be searched.
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/companies"
    query: [{name: companyNumber, var: company_number}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    company_number: $company_number, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/companies/{companyId}
#
# Returns: record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>>
# operationId: GetCompany
export def "get-company" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/companies/{companyId}"
    path_params: [{name: companyId, var: company_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    company_id: $company_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Check includes identifying bankruptcy, insolvency, CCJ's or Company Directorship.
#
# POST /api/credit-status/perform
# Returns: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: table<address1: string, address2: string, address3: string, address4: string, address5: string, amount: string, caseNumber: string, courtName: string, dateEnd: string, dob: string, judgementDate: string, judgementType: int, judgementTypeText: string, name: string, postcode: string>, checkDate: string, companyDirector: table<companyAppointments: list, companyName: string, companyRegNo: string, dateAppointed: string, matchType: int, matchTypeText: string, registeredOffice: string>, hasBeenOverridden: bool, insolvency: table<address: record, aliases: string, assetTotal: string, caseNo: string, caseType: string, court: string, debtTotal: string, description: string, dob: string, name: string, occupation: string, presentationDate: string, previousAddress: record, serviceOffice: string, startDate: string, status: string, telephoneNumber: string, tradingNames: string, type: int, typeText: string>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>
# operationId: CheckCreditStatus
export def "check-credit-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/credit-status/perform"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: person, var: person}, {name: regEntryId, var: reg_entry_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, address: $address, person: $person, reg_entry_id: $reg_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates new data check against a specified registration.
#
# POST /api/datachecks
# Returns: record<id: string, regCode: string>
# operationId: AddDataCheck
export def "add-data-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  check_type: int@check-type-completer # The value of checkType dictates what checks are performed. The StandardAml check (value = 1) will check DOB & Mortality. The InternationalPepSanctions check (value = 3) will check just International PEP & Sanctions. The EnhancedAml check (value = 2) will perform both these checks and is equivalent to making two calls with values of 1 then 3 and will be charged accordingly. values=> None = 0, StandardAml = 1, EnhancedAml = 2, InternationalPepSanctions = 3 (format: int32)
  current_address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/datachecks"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkType, var: check_type}, {name: currentAddress, var: current_address}, {name: person, var: person}, {name: regEntryId, var: reg_entry_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, check_type: $check_type, current_address: $current_address, person: $person, reg_entry_id: $reg_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add an id document image to the specified registration.
#
# POST /api/images/id-document
# Returns: record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string>
# operationId: AddIdDocumentImage
export def "add-id-document-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  --document-parameters: list # item shape: {key?: string, value?: string}
  document_type: int@document-type-completer # Other = 0, Passport = 1, DrivingLicence = 2, Visa = 3, CscsCard = 4, HomeOfficeLetter = 5, BirthCertificate = 6, NationalIdCard = 7, ResidencePermit = 9, UtilityBill = 11 (format: int32)
  image_data: string
  registration_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/images/id-document"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: documentParameters, var: document_parameters}, {name: documentType, var: document_type}, {name: imageData, var: image_data}, {name: registrationId, var: registration_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, document_parameters: $document_parameters, document_type: $document_type, image_data: $image_data, registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get all id document images associated with a registration.
#
# GET /api/images/id-document/{registrationId}
# Returns: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, hiResUrl: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcFacialUrl: string, nfcReadStatus: int, primaryScanId: string, status: int, surname: string, url: string>
# operationId: GetIdDocumentImages
export def "get-id-document-images" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/images/id-document/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a liveness image (UAP) to the specified registration.
#
# POST /api/images/liveness
# operationId: AddLivenessImage
export def "add-liveness-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied. (required)
  image_data: string
  registration_id: string # format: uuid
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/images/liveness"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageData, var: image_data}, {name: registrationId, var: registration_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, image_data: $image_data, registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the liveness performed image associated with a registration.
#
# GET /api/images/liveness-performed/{registrationId}
# Returns: record<base64Data: string, url: string>
# operationId: GetLivenessPerformedImage
export def "get-liveness-performed-image" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/images/liveness-performed/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the liveness action image (UAP) associated with a registration.
#
# GET /api/images/liveness/{registrationId}
# Returns: record<description: string, id: string, url: string>
# operationId: GetLivenessImage
export def "get-liveness-image" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/images/liveness/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a detailed report on the analysis that has taken place of a scanned document
#
# GET /api/images/scan-report-pdf/{scanId}
# Returns: string
# operationId: GetScanReportPdf
export def "get-scan-report-pdf" [
  scan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/images/scan-report-pdf/{scanId}"
    path_params: [{name: scanId, var: scan_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    scan_id: $scan_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add a selfie image to the registration.
#
# POST /api/images/selfie
# Returns: record<livenessConfirmed: bool>
# operationId: AddSelfieImage
export def "add-selfie-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  image_data: string
  registration_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/images/selfie"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: imageData, var: image_data}, {name: registrationId, var: registration_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, image_data: $image_data, registration_id: $registration_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the selfie image associated with a registration.
#
# GET /api/images/selfie/{registrationId}
# Returns: record<base64Data: string, url: string>
# operationId: GetSelfieImage
export def "get-selfie-image" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/images/selfie/{registrationId}"
    path_params: [{name: registrationId, var: registration_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    registration_id: $registration_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates new property registry check against the registration.
#
# POST /api/property-register
# Returns: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>
# operationId: AddPropertyRegisterCheck
export def "add-property-register-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/property-register"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: address, var: address}, {name: person, var: person}, {name: regEntryId, var: reg_entry_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, address: $address, person: $person, reg_entry_id: $reg_entry_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves property registry check associated with the registration.
#
# GET /api/property-register/{id}
# Returns: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>
# operationId: GetPropertyRegisterCheckResult
export def "get-property-register-check-result" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/property-register/{id}"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all available RegTypes.
#
# GET /api/reg-types
# Returns: table<id: string, name: string>
# operationId: GetAll
export def "get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/reg-types"
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates new registration.
#
# POST /api/registrations
# Returns: record<id: string, regCode: string, webJourneyUrl: record<url: string, validUntil: string>>
# operationId: AddRegistration
export def "add-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  --dialling-code: string
  --duplicate-acknowledgement: oneof<nothing, bool>
  --email-address: string
  forename: string
  --middle-name: string
  --parameters: list # item shape: {key?: string, value?: string}
  --phone-number: string
  --provide-web-journey-link: oneof<nothing, bool>
  --reference-id: string
  reg_type_id: string # format: uuid
  --return-urls: record # shape: {returnUrl?: string}
  --send-email: oneof<nothing, bool>
  --send-sms: oneof<nothing, bool>
  --settings: record # shape: {capturePersonalDetails?: bool, nameMatchRoutine?: "1"|"2", requiredChecks?: list<int>, skipEmailStep?: bool}
  --significant-person-id: string # format: uuid
  surname: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/registrations"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: diallingCode, var: dialling_code}, {name: duplicateAcknowledgement, var: duplicate_acknowledgement}, {name: emailAddress, var: email_address}, {name: forename, var: forename}, {name: middleName, var: middle_name}, {name: parameters, var: parameters}, {name: phoneNumber, var: phone_number}, {name: provideWebJourneyLink, var: provide_web_journey_link}, {name: referenceId, var: reference_id}, {name: regTypeId, var: reg_type_id}, {name: returnUrls, var: return_urls}, {name: sendEmail, var: send_email}, {name: sendSms, var: send_sms, required: true}, {name: settings, var: settings}, {name: significantPersonId, var: significant_person_id}, {name: surname, var: surname}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, dialling_code: $dialling_code, duplicate_acknowledgement: $duplicate_acknowledgement, email_address: $email_address, forename: $forename, middle_name: $middle_name, parameters: $parameters, phone_number: $phone_number, provide_web_journey_link: $provide_web_journey_link, reference_id: $reference_id, reg_type_id: $reg_type_id, return_urls: $return_urls, send_email: $send_email, send_sms: $send_sms, settings: $settings, significant_person_id: $significant_person_id, surname: $surname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates new registration record, adds an ID document and optional selfie image in one go.
#
# POST /api/registrations/instant
# Returns: record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string>
# operationId: AddInstantRegistration
export def "add-instant-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  document: string
  --document-parameters: list # item shape: {key?: string, value?: string}
  document_type: int@document-type-completer # Other = 0, Passport = 1, DrivingLicence = 2, Visa = 3, CscsCard = 4, HomeOfficeLetter = 5, BirthCertificate = 6, NationalIdCard = 7, ResidencePermit = 9, UtilityBill = 11 (format: int32)
  forename: string
  --middle-name: string
  --parameters: list # item shape: {key?: string, value?: string}
  --reference-id: string
  reg_type_id: string # format: uuid
  --selfie: string
  --significant-person-id: string # format: uuid
  surname: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/registrations/instant"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: document, var: document}, {name: documentParameters, var: document_parameters}, {name: documentType, var: document_type}, {name: forename, var: forename}, {name: middleName, var: middle_name}, {name: parameters, var: parameters}, {name: referenceId, var: reference_id}, {name: regTypeId, var: reg_type_id}, {name: selfie, var: selfie}, {name: significantPersonId, var: significant_person_id}, {name: surname, var: surname}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, document: $document, document_parameters: $document_parameters, document_type: $document_type, forename: $forename, middle_name: $middle_name, parameters: $parameters, reference_id: $reference_id, reg_type_id: $reg_type_id, selfie: $selfie, significant_person_id: $significant_person_id, surname: $surname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Finds registrations by the ReferenceId.
#
# GET /api/registrations/referenceid/{referenceId}/summary
# Returns: table<Comments: list<record>, DITFDate: string, DITFStatus: int, bankAccountChecks: list<record>, createdByAgencyUserId: string, creditStatusCheck: record<address: record, ccj: list, checkDate: string, companyDirector: list, hasBeenOverridden: bool, insolvency: list, person: record, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list<record>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list<record>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>
# operationId: GetRegistrationSummariesByReferenceId
export def "get-registration-summaries-by-reference-id" [
  reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/referenceid/{referenceId}/summary"
    path_params: [{name: referenceId, var: reference_id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    reference_id: $reference_id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Finds a registration by the RegCode.
#
# GET /api/registrations/regcode/{regCode}/summary
# Returns: record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>
# operationId: GetRegistrationSummaryByRegCode
export def "get-registration-summary-by-reg-code" [
  reg_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/regcode/{regCode}/summary"
    path_params: [{name: regCode, var: reg_code}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    reg_code: $reg_code, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets paged registration list by search criteria or nothing if there are no matching fields. Optional parameters may be appended to the query string. Maximum page size is 50.
#
# GET /api/registrations/search
# Returns: record<registrationSummaries: table<Comments: list, DITFDate: string, DITFStatus: int, bankAccountChecks: list, createdByAgencyUserId: string, creditStatusCheck: record, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list, idVerification: record, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record, phoneNumber: string, proofOfOwnershipCheck: record, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record, rightToWorkCheck: record, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>, totalCount: int>
# operationId: GetRegistrationSearch
export def "get-registration-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-num: int # Zero-based page number to retrieve. (format: int32, default: 0)
  --page-size: int # Number of records to return on each request (Maximum value is 50). (format: int32, default: 50)
  --forename: string # Search by forename.
  --surname: string # Search by surname.
  --email: string # Search by user email.
  --dob: string # Date of birth in (yyyy-MM-dd) format
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/search"
    query: [{name: pageNum, var: page_num}, {name: pageSize, var: page_size}, {name: forename, var: forename}, {name: surname, var: surname}, {name: email, var: email}, {name: dob, var: dob}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    page_num: $page_num, page_size: $page_size, forename: $forename, surname: $surname, email: $email, dob: $dob, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Checks if submitted documents are sufficient to complete registration.
#
# GET /api/registrations/{id}/check-submitted-id-documents
# Returns: record<checkCode: int, message: string>
# operationId: CheckSubmittedIdDocuments
export def "check-submitted-id-documents" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/{id}/check-submitted-id-documents"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates a registration's contact details.
#
# PUT /api/registrations/{id}/contact-details
# operationId: UpdateContactDetails
export def "update-contact-details" [
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
  --apikey: string # ApiKey supplied. (required)
  --delivery-method: int@delivery-method-completer # None = 0, Email = 1, Sms = 2 (format: int32)
  --dialling-code: string
  --email: string
  forename: string
  --middle-name: string
  --phone-number: string
  surname: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/registrations/{id}/contact-details"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: deliveryMethod, var: delivery_method}, {name: diallingCode, var: dialling_code}, {name: email, var: email}, {name: forename, var: forename}, {name: middleName, var: middle_name}, {name: phoneNumber, var: phone_number}, {name: surname, var: surname}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey, delivery_method: $delivery_method, dialling_code: $dialling_code, email: $email, forename: $forename, middle_name: $middle_name, phone_number: $phone_number, surname: $surname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets an override for a specific check on the registration.
#
# PUT /api/registrations/{id}/override-check-status
# operationId: OverrideCheckStatus
export def "override-check-status" [
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
  --apikey: string # ApiKey supplied. (required)
  check_type: int@check-type-completer-1 # IdDocuments = 1, StandardChecks = 2, InternationalSanctionsAndPep = 3, CreditStatusCheck = 4, BankAccountCheck = 5, ProofOfOwnership = 6, RightToWork = 7, RightToRent = 8 (format: int32)
  comment: string
  status: int@status-completer # Unknown = 0, Pass = 1, Refer = 2, Fail = 3 (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/registrations/{id}/override-check-status"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: checkType, var: check_type}, {name: comment, var: comment}, {name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey, check_type: $check_type, comment: $comment, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns PDF export for a given registration.
#
# GET /api/registrations/{id}/pdf-export
# Returns: string
# operationId: GetRegistrationPdfExport
export def "get-registration-pdf-export" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/registrations/{id}/pdf-export"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns a PDF report for a given registration containing specified sections
#
# GET /api/registrations/{id}/pdf-export-sections
# Returns: string
export def "get-api-registrations-id-pdf-export-sections" [
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
  --comments: oneof<nothing, bool>
  --contact-details: oneof<nothing, bool>
  --standard-checks: oneof<nothing, bool>
  --pep-sanction-checks: oneof<nothing, bool>
  --proof-of-ownership: oneof<nothing, bool>
  --bank-account-check: oneof<nothing, bool>
  --credit-status-check: oneof<nothing, bool>
  --liveness: oneof<nothing, bool>
  --exclude-selfie: oneof<nothing, bool>
  --exclude-id-documents: oneof<nothing, bool>
  --diatf-section: oneof<nothing, bool>
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/registrations/{id}/pdf-export-sections"
    path_params: [{name: id, var: id}]
    query: [{name: Comments, var: comments}, {name: ContactDetails, var: contact_details}, {name: StandardChecks, var: standard_checks}, {name: PepSanctionChecks, var: pep_sanction_checks}, {name: ProofOfOwnership, var: proof_of_ownership}, {name: BankAccountCheck, var: bank_account_check}, {name: CreditStatusCheck, var: credit_status_check}, {name: Liveness, var: liveness}, {name: ExcludeSelfie, var: exclude_selfie}, {name: ExcludeIDDocuments, var: exclude_id_documents}, {name: DIATFSection, var: diatf_section}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, comments: $comments, contact_details: $contact_details, standard_checks: $standard_checks, pep_sanction_checks: $pep_sanction_checks, proof_of_ownership: $proof_of_ownership, bank_account_check: $bank_account_check, credit_status_check: $credit_status_check, liveness: $liveness, exclude_selfie: $exclude_selfie, exclude_id_documents: $exclude_id_documents, diatf_section: $diatf_section, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Returns settlement status PDF (Share Code) for a given registration.
#
# GET /api/registrations/{id}/pdf-settlement-status
# Returns: string
# operationId: GetShareCodePdfExport
export def "get-share-code-pdf-export" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/registrations/{id}/pdf-settlement-status"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Resends any invitation for the specified registration.
#
# POST /api/registrations/{id}/resend-invitation
# operationId: ResendInvitation
export def "resend-invitation" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/registrations/{id}/resend-invitation"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets registration settings or nothing if there are no settings associated with the registration.
#
# GET /api/registrations/{id}/settings
# operationId: GetRegistrationSettings
export def "get-registration-settings" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/api/registrations/{id}/settings"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates registration settings.
#
# PUT /api/registrations/{id}/settings
# operationId: UpdateRegistrationSettings
export def "update-registration-settings" [
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
  --apikey: string # ApiKey supplied. (required)
  --capture-personal-details: oneof<nothing, bool>
  --name-match-routine: int@name-match-routine-completer # Fuzzy = 1, Strict = 2 (format: int32)
  --required-checks: list<int> # The value of required checks determines what checks are performed. Unknown = 0,Id Documents = 1, Standard Checks = 2, International Sanctions and Pep = 3, Credit Status Check = 4, Bank Account Check = 5, Proof of Ownership = 6, Right to Work = 7, Right to Rent = 8
  --skip-email-step: oneof<nothing, bool>
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/registrations/{id}/settings"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: capturePersonalDetails, var: capture_personal_details}, {name: nameMatchRoutine, var: name_match_routine}, {name: requiredChecks, var: required_checks}, {name: skipEmailStep, var: skip_email_step}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey, capture_personal_details: $capture_personal_details, name_match_routine: $name_match_routine, required_checks: $required_checks, skip_email_step: $skip_email_step
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates the status of the registration to one specified in the request.
#
# PUT /api/registrations/{id}/status
# operationId: UpdateRegistrationStatus
export def "update-registration-status" [
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
  --apikey: string # ApiKey supplied. (required)
  status: int@status-completer-1 # Unknown = 0, Submitted = 1, Approved = 2, Rejected = 3, Exported = 4, Invited = 6 (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/registrations/{id}/status"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Finds a registration by the Id.
#
# GET /api/registrations/{id}/summary
# Returns: record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>
# operationId: GetRegistrationSummary
export def "get-registration-summary" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/{id}/summary"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Get a list of supported id document for the specified registration id.
#
# GET /api/registrations/{id}/supported-id-documents
# Returns: record<name: string, type: int>
# operationId: GetRegistrationSupportedIdDocuments
export def "get-registration-supported-id-documents" [
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
  --apikey: string # ApiKey supplied. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/registrations/{id}/supported-id-documents"
    path_params: [{name: id, var: id}]
    header: [{name: apikey, var: apikey, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    id: $id, apikey: $apikey
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves secure links to registration details pages searching by the Reference Id.
#
# POST /api/report-view/by-referenceid
# Returns: record<results: table<forename: string, surname: string, url: string, validUntil: string>>
# operationId: GetReportViewByReferenceId
export def "get-report-view-by-reference-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  --can-change-status: oneof<nothing, bool>
  --can-verify: oneof<nothing, bool>
  reference_id: string
  --user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/report-view/by-referenceid"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: canChangeStatus, var: can_change_status}, {name: canVerify, var: can_verify}, {name: referenceId, var: reference_id}, {name: user, var: user}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, can_change_status: $can_change_status, can_verify: $can_verify, reference_id: $reference_id, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves secure link to registration details page searching by the Registration Id.
#
# POST /api/report-view/by-registrationid
# Returns: record<results: table<forename: string, surname: string, url: string, validUntil: string>>
# operationId: GetReportViewByRegistrationId
export def "get-report-view-by-registration-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  --can-change-status: oneof<nothing, bool>
  --can-verify: oneof<nothing, bool>
  registration_id: string # format: uuid
  --user: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/report-view/by-registrationid"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: canChangeStatus, var: can_change_status}, {name: canVerify, var: can_verify}, {name: registrationId, var: registration_id}, {name: user, var: user}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, can_change_status: $can_change_status, can_verify: $can_verify, registration_id: $registration_id, user: $user
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves secure links to web verification pages searching by the Reference Id.
#
# POST /api/web-verifications/by-referenceid
# Returns: record<results: table<journeyUrl: record>>
# operationId: GetWebVerificationsByReferenceId
export def "get-web-verifications-by-reference-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  reference_id: string
  --return-urls: record # shape: {returnUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/web-verifications/by-referenceid"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: referenceId, var: reference_id}, {name: returnUrls, var: return_urls}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, reference_id: $reference_id, return_urls: $return_urls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves secure link to web verification page searching by the Registration Id.
#
# POST /api/web-verifications/by-registrationid
# Returns: record<results: table<journeyUrl: record>>
# operationId: GetWebVerificationsByRegistrationId
export def "get-web-verifications-by-registration-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied. (required)
  registration_id: string # format: uuid
  --return-urls: record # shape: {returnUrl?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/web-verifications/by-registrationid"
    header: [{name: apikey, var: apikey, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: registrationId, var: registration_id}, {name: returnUrls, var: return_urls}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    apikey: $apikey, registration_id: $registration_id, return_urls: $return_urls
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
