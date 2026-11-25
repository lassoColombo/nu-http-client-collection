# Auto-generated client for Ritc v1.0.0
# Source: https://api.apis.guru/v2/specs/ritc.io/1.0.0/swagger.json
# Auth: --token flag or $env.RITC_TOKEN

const CLIENT = {
  base_url: "https://api.ritc.io"
  token_env_var: "RITC_TOKEN"
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

def base-url-completer [] { ["https://api.ritc.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def auth-type-completer [] { ["apikey" "basic" "none" "oauth2"] }
def status-completer [] { ["active" "inactive"] }
def api-type-completer [] { ["Internal" "REST" "SDK"] }
def http-method-completer [] { ["DELETE" "GET" "PATCH" "POST"] }
def response-format-completer [] { ["Html" "Json" "Text" "Xml"] }
def type-completer [] { ["action" "trigger"] }
def type-completer-1 [] { ["admin" "guest"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list-actions: "table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>"
    add-action: "record<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>"
    get-action: "table<channelId: int, codes: record, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, parameters: record, status: string>"
    update-action: "record<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>"
    admin: "record"
    log-in-ritc: "record"
    ping-ritc: "record"
    list-apps: "table<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    add-app: "record<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    list-app-channels: "table<channelId: int, createdDate: string, id: int, status: string, userId: int>"
    list-app-channel-users: "table<channelId: int, createdDate: string, id: int, status: string, userId: int>"
    get-app-channel-user: "table<channelId: int, createdDate: string, id: int, status: string, userId: int>"
    add-app-channel-user: "record<channelId: int, createdDate: string, id: int, status: string, userId: int>"
    list-channel-external-credentials: "table<authType: string, channel_id: string, credentials: record, id: string, name: string>"
    add-channel-external-credentials: "record<authType: string, channel_id: string, credentials: record, id: string, name: string>"
    get-channel-external-credentials: "table<authType: string, channel_id: string, credentials: record, id: string, name: string>"
    update-channel-external-credentials: "record<authType: string, channel_id: string, credentials: record, id: string, name: string>"
    run-rule-group: "table<id: string, name: string, type: string>"
    run-app: "table<id: string, name: string, type: string>"
    get-app: "table<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    update-app: "record<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    list-channels: "table<description: string, functions: list<record>, id: string, name: string, type: record>"
    add-channel: "record<description: string, functions: table<description: string, id: string, name: string, type: string>, id: string, name: string, type: record>"
    list-anonymous-channels: "table<description: string, functions: list<record>, id: string, name: string, type: record>"
    get-channel: "table<description: string, functions: list<record>, id: string, name: string, type: record>"
    update-channel: "record<description: string, functions: table<description: string, id: string, name: string, type: string>, id: string, name: string, type: record>"
    list-channel-functions: "table<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: list<record>, responseFormat: string, type: string>"
    add-channel-function: "record<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: table<description: string, fieldType: string, label: string, name: string, schema: record>, responseFormat: string, type: string>"
    get-channel-function: "table<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: list<record>, responseFormat: string, type: string>"
    add-organization: "table<createdDate: string, id: string, modifiedDate: string, name: string, plan: string, planCat: record, status: string, type: record>"
    get-my-organization: "table<createdDate: string, id: string, modifiedDate: string, name: string, plan: string, planCat: record, status: string, type: record>"
    list-rules: "table<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>"
    add-rule: "record<actions: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>>"
    get-rule: "table<actions: list<record>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: list<record>>"
    update-rule: "record<actions: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>>"
    run-rule: "record"
    list-triggers: "table<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>"
    add-trigger: "record<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>"
    get-trigger: "table<channelId: int, codes: record, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, parameters: record, status: string>"
    update-trigger: "record<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>"
    list-app-users: "table<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    add-app-user: "record<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    list-admin-users: "table<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>"
    add-admin-user: "record<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>"
    get-admin-user: "table<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>"
    update-admin-user: "record<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>"
    authenticate-app-user-for-channel: "table<url: string>"
    get-app-user: "table<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    update-app-user: "record<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>"
    list-app-user-channels: "table<channelId: int, userId: int>"
    add-app-user-to-channel: "record<channelId: int, userId: int>"
    get-app-user-channel: "table<channelId: int, userId: int>"
    list-app-user-rules: "table<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>"
    get-app-user-rule: "table<actions: list<record>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: list<record>>"
    add-app-user-to-rule: "record<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>"
    run-rule-for-app-user: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-actions" "add-action" "remove-action" "get-action" "update-action" "admin" "log-in-ritc" "ping-ritc" "list-apps" "add-app" "list-app-channels" "list-app-channel-users" "get-app-channel-user" "add-app-channel-user" "list-channel-external-credentials" "add-channel-external-credentials" "remove-channel-external-credentials" "get-channel-external-credentials" "update-channel-external-credentials" "run-rule-group" "run-app" "remove-app" "get-app" "update-app" "list-channels" "add-channel" "list-anonymous-channels" "remove-channel" "get-channel" "update-channel" "list-channel-functions" "add-channel-function" "get-channel-function" "add-organization" "get-my-organization" "list-rules" "add-rule" "remove-rule" "get-rule" "update-rule" "run-rule" "list-triggers" "add-trigger" "remove-trigger" "get-trigger" "update-trigger" "list-app-users" "add-app-user" "list-admin-users" "add-admin-user" "remove-admin-user" "get-admin-user" "update-admin-user" "authenticate-app-user-for-channel" "remove-app-user" "get-app-user" "update-app-user" "list-app-user-channels" "add-app-user-to-channel" "remove-app-user-from-channel" "get-app-user-channel" "list-app-user-rules" "remove-app-user-from-rule" "get-app-user-rule" "add-app-user-to-rule" "run-rule-for-app-user" "commands"] | sort) } | get name | first)
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

# List actions
#
# GET /actions
# Returns: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: listActions
export def "list-actions" [
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
    path: "/actions"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new action
#
# POST /actions
# Returns: record<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: addAction
export def "add-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: int # Id of channel used by action (format: int32)
  --codes: record # Object containing named Javascript code sets
  --desc: string # Action description
  function_id: string # Hash id of channel function used by action
  name: string # Action name
  --parameters: record # Object containing channel-defined action parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/actions"
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: codes, var: codes}, {name: desc, var: desc}, {name: functionId, var: function_id}, {name: name, var: name}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, codes: $codes, desc: $desc, function_id: $function_id, name: $name, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an action
#
# DELETE /actions/{action_id}
# operationId: removeAction
export def "remove-action" [
  action_id: string
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
    path: "/actions/{action_id}"
    path_params: [{name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an action
#
# GET /actions/{action_id}
# Returns: table<channelId: int, codes: record, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, parameters: record, status: string>
# operationId: getAction
export def "get-action" [
  action_id: string
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
    path: "/actions/{action_id}"
    path_params: [{name: action_id, var: action_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information about a specific action
#
# PATCH /actions/{action_id}
# Returns: record<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: updateAction
export def "update-action" [
  action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: int # Id of channel used by action (format: int32)
  --codes: record # Object containing named Javascript code sets
  --desc: string # Action description
  function_id: string # Hash id of channel function used by action
  name: string # Action name
  --parameters: record # Object containing channel-defined action parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/actions/{action_id}"
    path_params: [{name: action_id, var: action_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: codes, var: codes}, {name: desc, var: desc}, {name: functionId, var: function_id}, {name: name, var: name}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_id: $action_id, channel_id: $channel_id, codes: $codes, desc: $desc, function_id: $function_id, name: $name, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping the server
#
# GET /admin
# Returns: record
# operationId: admin
export def "admin" [
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
    path: "/admin"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Log a message
#
# POST /admin/log
# Returns: record
# operationId: logInRitc
export def "log-in-ritc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/admin/log"
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ping the server
#
# GET /admin/ping
# Returns: record
# operationId: pingRitc
export def "ping-ritc" [
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
    path: "/admin/ping"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get apps information
#
# GET /apps
# Returns: table<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: listApps
export def "list-apps" [
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
    path: "/apps"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new app
#
# POST /apps
# Returns: record<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: addApp
export def "add-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --desc: string # App description
  --name: string # App name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps"
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    desc: $desc, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get app channels
#
# GET /apps/channels/users
# Returns: table<channelId: int, createdDate: string, id: int, status: string, userId: int>
# operationId: listAppChannels
export def "list-app-channels" [
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
    path: "/apps/channels/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users of a specified channel
#
# GET /apps/channels/{channel_id}/users
# Returns: table<channelId: int, createdDate: string, id: int, status: string, userId: int>
# operationId: listAppChannelUsers
export def "list-app-channel-users" [
  channel_id: string
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
    path: "/apps/channels/{channel_id}/users"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user of a specified channel
#
# GET /apps/channels/{channel_id}/users/{user_id}
# Returns: table<channelId: int, createdDate: string, id: int, status: string, userId: int>
# operationId: getAppChannelUser
export def "get-app-channel-user" [
  channel_id: string
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/channels/{channel_id}/users/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create user channel
#
# POST /apps/channels/{channel_id}/users/{user_id}
# Returns: record<channelId: int, createdDate: string, id: int, status: string, userId: int>
# operationId: addAppChannelUser
export def "add-app-channel-user" [
  channel_id: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/apps/channels/{channel_id}/users/{user_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get external credentials
#
# GET /apps/ext/api/credentials
# Returns: table<authType: string, channel_id: string, credentials: record, id: string, name: string>
# operationId: listChannelExternalCredentials
export def "list-channel-external-credentials" [
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
    path: "/apps/ext/api/credentials"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new external credentials
#
# POST /apps/ext/api/credentials
# Returns: record<authType: string, channel_id: string, credentials: record, id: string, name: string>
# operationId: addChannelExternalCredentials
export def "add-channel-external-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string@auth-type-completer
  --channel-id: string
  --credentials: record
  --name: string # App external credentials api name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/ext/api/credentials"
    body: {content_type: "application/json", kind: json, fields: [{name: authType, var: auth_type}, {name: channel_id, var: channel_id}, {name: credentials, var: credentials}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    auth_type: $auth_type, channel_id: $channel_id, credentials: $credentials, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete credentials for a channel
#
# DELETE /apps/ext/api/credentials/{channel_id}
# operationId: removeChannelExternalCredentials
export def "remove-channel-external-credentials" [
  channel_id: string
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
    path: "/apps/ext/api/credentials/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get credentials for a channel in an app
#
# GET /apps/ext/api/credentials/{channel_id}
# Returns: table<authType: string, channel_id: string, credentials: record, id: string, name: string>
# operationId: getChannelExternalCredentials
export def "get-channel-external-credentials" [
  channel_id: string
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
    path: "/apps/ext/api/credentials/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update credentials for a channel
#
# PATCH /apps/ext/api/credentials/{channel_id}
# Returns: record<authType: string, channel_id: string, credentials: record, id: string, name: string>
# operationId: updateChannelExternalCredentials
export def "update-channel-external-credentials" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string@auth-type-completer
  --body-channel-id: string # (spec name: channel_id)
  --credentials: record
  --name: string # App external credentials api name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/ext/api/credentials/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authType, var: auth_type}, {name: channel_id, var: body_channel_id}, {name: credentials, var: credentials}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, auth_type: $auth_type, body_channel_id: $body_channel_id, credentials: $credentials, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run specified rule group in the app
#
# POST /apps/rulegroup/run/{rule_id_list}
# Returns: table<id: string, name: string, type: string>
# operationId: runRuleGroup
export def "run-rule-group" [
  rule_id_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --break-when-rule-fires: oneof<nothing, bool> # Do not continue with remaining rules after a rule fires
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/rulegroup/run/{rule_id_list}"
    path_params: [{name: rule_id_list, var: rule_id_list}]
    query: [{name: break_when_rule_fires, var: break_when_rule_fires}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id_list: $rule_id_list, break_when_rule_fires: $break_when_rule_fires, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run active app rules
#
# POST /apps/rules/run
# Returns: table<id: string, name: string, type: string>
# operationId: runApp
export def "run-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --break-when-rule-fires: oneof<nothing, bool> # Do not continue with remaining rules after a rule fires
  --body: record
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/apps/rules/run"
    query: [{name: break_when_rule_fires, var: break_when_rule_fires}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    break_when_rule_fires: $break_when_rule_fires, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an app
#
# DELETE /apps/{app_id}
# operationId: removeApp
export def "remove-app" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/apps/{app_id}"
    path_params: [{name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get app information
#
# GET /apps/{app_id}
# Returns: table<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: getApp
export def "get-app" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/apps/{app_id}"
    path_params: [{name: app_id, var: app_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an app
#
# PATCH /apps/{app_id}
# Returns: record<apiKey: string, createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: updateApp
export def "update-app" [
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
  --desc: string # App description
  --name: string # App name
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/apps/{app_id}"
    path_params: [{name: app_id, var: app_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: name, var: name}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    app_id: $app_id, desc: $desc, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Channels
#
# GET /channels
# Returns: table<description: string, functions: list<record>, id: string, name: string, type: record>
# operationId: listChannels
export def "list-channels" [
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
    path: "/channels"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a channel
#
# POST /channels
# Returns: record<description: string, functions: table<description: string, id: string, name: string, type: string>, id: string, name: string, type: record>
# operationId: addChannel
export def "add-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Channel description
  --functions: list # item shape: {id?: string, name?: string, parameters?: list, type?: "action"|"trigger"}
  --id: string # Id of channel
  --name: string # Channel name
  --type: record # Type of channel. Choices are 'public' or 'private'. Private channels are only viewable within an account, while public channels are viewable to everyone in the system
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: functions, var: functions}, {name: id, var: id}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, functions: $functions, id: $id, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Channels anonymously
#
# GET /channels/anonymous
# Returns: table<description: string, functions: list<record>, id: string, name: string, type: record>
# operationId: listAnonymousChannels
export def "list-anonymous-channels" [
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
    path: "/channels/anonymous"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a channel
#
# DELETE /channels/{channel_id}
# operationId: removeChannel
export def "remove-channel" [
  channel_id: string
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
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel information
#
# GET /channels/{channel_id}
# Returns: table<description: string, functions: list<record>, id: string, name: string, type: record>
# operationId: getChannel
export def "get-channel" [
  channel_id: string
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
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a channel
#
# PATCH /channels/{channel_id}
# Returns: record<description: string, functions: table<description: string, id: string, name: string, type: string>, id: string, name: string, type: record>
# operationId: updateChannel
export def "update-channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-ids: string # Rule description
  --description: string # Rule description
  --name: string # Rule name
  --status: string@status-completer
  --trigger-ids: string # Rule description
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/channels/{channel_id}"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionIds, var: action_ids}, {name: description, var: description}, {name: name, var: name}, {name: status, var: status}, {name: triggerIds, var: trigger_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, action_ids: $action_ids, description: $description, name: $name, status: $status, trigger_ids: $trigger_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve Channel Functions
#
# GET /channels/{channel_id}/functions
# Returns: table<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: list<record>, responseFormat: string, type: string>
# operationId: listChannelFunctions
export def "list-channel-functions" [
  channel_id: string
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
    path: "/channels/{channel_id}/functions"
    path_params: [{name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a channel function
#
# POST /channels/{channel_id}/functions
# Returns: record<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: table<description: string, fieldType: string, label: string, name: string, schema: record>, responseFormat: string, type: string>
# operationId: addChannelFunction
export def "add-channel-function" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-type: string@api-type-completer
  --desc: string # Function description
  --endpoint: string # Function endpoint
  --http-method: string@http-method-completer
  --name: string # Function name
  --request-parameters: list # item shape: {description?: string, fieldType?: string, label?: string, name?: string, schema?: record}
  --response-format: string@response-format-completer
  --type: string@type-completer
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/channels/{channel_id}/functions"
    path_params: [{name: channel_id, var: channel_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: apiType, var: api_type}, {name: desc, var: desc}, {name: endpoint, var: endpoint}, {name: httpMethod, var: http_method}, {name: name, var: name}, {name: requestParameters, var: request_parameters}, {name: responseFormat, var: response_format}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, api_type: $api_type, desc: $desc, endpoint: $endpoint, http_method: $http_method, name: $name, request_parameters: $request_parameters, response_format: $response_format, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel function information
#
# GET /channels/{channel_id}/functions/{function_id}
# Returns: table<apiType: string, description: string, endpoint: string, httpMethod: string, id: string, name: string, requestParameters: list<record>, responseFormat: string, type: string>
# operationId: getChannelFunction
export def "get-channel-function" [
  channel_id: string
  function_id: string
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
    path: "/channels/{channel_id}/functions/{function_id}"
    path_params: [{name: channel_id, var: channel_id}, {name: function_id, var: function_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, function_id: $function_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an org
#
# POST /orgs
# Returns: table<createdDate: string, id: string, modifiedDate: string, name: string, plan: string, planCat: record, status: string, type: record>
# operationId: addOrganization
export def "add-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --desc: string # Org description
  name: string # Org name
  --type: string # Org type
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orgs"
    body: {content_type: "application/json", kind: json, fields: [{name: desc, var: desc}, {name: name, var: name}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    desc: $desc, name: $name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get org information
#
# GET /orgs/me
# Returns: table<createdDate: string, id: string, modifiedDate: string, name: string, plan: string, planCat: record, status: string, type: record>
# operationId: getMyOrganization
export def "get-my-organization" [
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
    path: "/orgs/me"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rules
#
# GET /rules
# Returns: table<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: listRules
export def "list-rules" [
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
    path: "/rules"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new rule
#
# POST /rules
# Returns: record<actions: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>>
# operationId: addRule
export def "add-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-ids: string # Rule description
  --description: string # Rule description
  --name: string # Rule name
  --status: string@status-completer
  --trigger-ids: string # Rule description
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules"
    body: {content_type: "application/json", kind: json, fields: [{name: actionIds, var: action_ids}, {name: description, var: description}, {name: name, var: name}, {name: status, var: status}, {name: triggerIds, var: trigger_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    action_ids: $action_ids, description: $description, name: $name, status: $status, trigger_ids: $trigger_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a rule
#
# DELETE /rules/{rule_id}
# operationId: removeRule
export def "remove-rule" [
  rule_id: string
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
    path: "/rules/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a rule
#
# GET /rules/{rule_id}
# Returns: table<actions: list<record>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: list<record>>
# operationId: getRule
export def "get-rule" [
  rule_id: string
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
    path: "/rules/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information about a specific rule
#
# PATCH /rules/{rule_id}
# Returns: record<actions: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: table<channelId: string, createdDate: string, description: string, functionId: string, id: string, modifiedDate: string, name: string, status: string>>
# operationId: updateRule
export def "update-rule" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action-ids: string # Rule description
  --description: string # Rule description
  --name: string # Rule name
  --status: string@status-completer
  --trigger-ids: string # Rule description
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/rules/{rule_id}"
    path_params: [{name: rule_id, var: rule_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: actionIds, var: action_ids}, {name: description, var: description}, {name: name, var: name}, {name: status, var: status}, {name: triggerIds, var: trigger_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, action_ids: $action_ids, description: $description, name: $name, status: $status, trigger_ids: $trigger_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run a rule
#
# POST /rules/{rule_id}/run
# Returns: record
# operationId: runRule
export def "run-rule" [
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/rules/{rule_id}/run"
    path_params: [{name: rule_id, var: rule_id}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    rule_id: $rule_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Triggers in an app
#
# GET /triggers
# Returns: table<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: listTriggers
export def "list-triggers" [
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
    path: "/triggers"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new trigger in an app
#
# POST /triggers
# Returns: record<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: addTrigger
export def "add-trigger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: int # Id of channel used by trigger (format: int32)
  --codes: record # Object containing named Javascript code sets
  --desc: string # Trigger description
  function_id: string # Hash id of channel function used by trigger
  name: string # Trigger name
  --parameters: record # Object containing channel-defined trigger parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/triggers"
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: codes, var: codes}, {name: desc, var: desc}, {name: functionId, var: function_id}, {name: name, var: name}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    channel_id: $channel_id, codes: $codes, desc: $desc, function_id: $function_id, name: $name, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a trigger
#
# DELETE /triggers/{trigger_id}
# operationId: removeTrigger
export def "remove-trigger" [
  trigger_id: string
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
    path: "/triggers/{trigger_id}"
    path_params: [{name: trigger_id, var: trigger_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a trigger
#
# GET /triggers/{trigger_id}
# Returns: table<channelId: int, codes: record, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, parameters: record, status: string>
# operationId: getTrigger
export def "get-trigger" [
  trigger_id: string
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
    path: "/triggers/{trigger_id}"
    path_params: [{name: trigger_id, var: trigger_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trigger_id: $trigger_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a trigger
#
# PATCH /triggers/{trigger_id}
# Returns: record<channelId: int, createdDate: string, description: string, functionId: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: updateTrigger
export def "update-trigger" [
  trigger_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: int # Id of channel used by trigger (format: int32)
  --codes: record # Object containing named Javascript code sets
  --desc: string # Trigger description
  function_id: string # Hash id of channel function used by trigger
  name: string # Trigger name
  --parameters: record # Object containing channel-defined trigger parameters
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/triggers/{trigger_id}"
    path_params: [{name: trigger_id, var: trigger_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: channelId, var: channel_id}, {name: codes, var: codes}, {name: desc, var: desc}, {name: functionId, var: function_id}, {name: name, var: name}, {name: parameters, var: parameters}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    trigger_id: $trigger_id, channel_id: $channel_id, codes: $codes, desc: $desc, function_id: $function_id, name: $name, parameters: $parameters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Users
#
# GET /users
# Returns: table<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: listAppUsers
export def "list-app-users" [
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
    path: "/users"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new App User
#
# POST /users
# Returns: record<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: addAppUser
export def "add-app-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # Object containing user-defined app user configuration
  --name: string # Display name of App User
  --password: string # App User password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users"
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: name, var: name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    config: $config, name: $name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Admin users
#
# GET /users/admin
# Returns: table<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: listAdminUsers
export def "list-admin-users" [
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
    path: "/users/admin"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new admin user
#
# POST /users/admin
# Returns: record<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: addAdminUser
export def "add-admin-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Admin User email address
  --password: string # Admin User password
  --type: string@type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/admin"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, password: $password, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove an admin user
#
# DELETE /users/admin/{user_id}
# operationId: removeAdminUser
export def "remove-admin-user" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/admin/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an admin user
#
# GET /users/admin/{user_id}
# Returns: table<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: getAdminUser
export def "get-admin-user" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/admin/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information about an admin user
#
# PATCH /users/admin/{user_id}
# Returns: record<createdDate: string, email: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: updateAdminUser
export def "update-admin-user" [
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
  --email: string # Admin User email address
  --password: string # Admin User password
  --type: string@type-completer-1
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/admin/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}, {name: type, var: type}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, email: $email, password: $password, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Authenticate a user for a channel
#
# POST /users/authenticate/{user_id}/channel/{channel_id}
# Returns: table<url: string>
# operationId: authenticateAppUserForChannel
export def "authenticate-app-user-for-channel" [
  user_id: string
  channel_id: string
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
    method: post
    path: "/users/authenticate/{user_id}/channel/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user
#
# DELETE /users/{user_id}
# operationId: removeAppUser
export def "remove-app-user" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an App User
#
# GET /users/{user_id}
# Returns: table<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: getAppUser
export def "get-app-user" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update information about an App User
#
# PATCH /users/{user_id}
# Returns: record<createdDate: string, description: string, id: string, modifiedDate: string, name: string, status: string>
# operationId: updateAppUser
export def "update-app-user" [
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
  --config: record # Object containing user-defined app user configuration
  --name: string # Display name of App User
  --password: string # App User password
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/users/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: config, var: config}, {name: name, var: name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, config: $config, name: $name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Channels available to a User
#
# GET /users/{user_id}/channels
# Returns: table<channelId: int, userId: int>
# operationId: listAppUserChannels
export def "list-app-user-channels" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/channels"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a channel to a user
#
# POST /users/{user_id}/channels
# Returns: record<channelId: int, userId: int>
# operationId: addAppUserToChannel
export def "add-app-user-to-channel" [
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
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/users/{user_id}/channels"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user channel assignment
#
# DELETE /users/{user_id}/channels/{channel_id}
# operationId: removeAppUserFromChannel
export def "remove-app-user-from-channel" [
  user_id: string
  channel_id: string
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
    path: "/users/{user_id}/channels/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user channel
#
# GET /users/{user_id}/channels/{channel_id}
# Returns: table<channelId: int, userId: int>
# operationId: getAppUserChannel
export def "get-app-user-channel" [
  user_id: string
  channel_id: string
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
    path: "/users/{user_id}/channels/{channel_id}"
    path_params: [{name: user_id, var: user_id}, {name: channel_id, var: channel_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, channel_id: $channel_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Rules for a User
#
# GET /users/{user_id}/rules
# Returns: table<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: listAppUserRules
export def "list-app-user-rules" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/rules"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a rule user
#
# DELETE /users/{user_id}/rules/{rule_id}
# operationId: removeAppUserFromRule
export def "remove-app-user-from-rule" [
  user_id: string
  rule_id: string
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
    path: "/users/{user_id}/rules/{rule_id}"
    path_params: [{name: user_id, var: user_id}, {name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{user_id}/rules/{rule_id}
# Returns: table<actions: list<record>, createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string, triggers: list<record>>
# operationId: getAppUserRule
export def "get-app-user-rule" [
  user_id: string
  rule_id: string
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
    path: "/users/{user_id}/rules/{rule_id}"
    path_params: [{name: user_id, var: user_id}, {name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a user to a rule
#
# POST /users/{user_id}/rules/{rule_id}
# Returns: record<createdDate: string, description: string, id: int, modifiedDate: string, name: string, status: string>
# operationId: addAppUserToRule
export def "add-app-user-to-rule" [
  user_id: string
  rule_id: string
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
    path: "/users/{user_id}/rules/{rule_id}"
    path_params: [{name: user_id, var: user_id}, {name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Run rule for a user
#
# POST /users/{user_id}/rules/{rule_id}/run
# Returns: record
# operationId: runRuleForAppUser
export def "run-rule-for-app-user" [
  user_id: string
  rule_id: string
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
    path: "/users/{user_id}/rules/{rule_id}/run"
    path_params: [{name: user_id, var: user_id}, {name: rule_id, var: rule_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, rule_id: $rule_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
