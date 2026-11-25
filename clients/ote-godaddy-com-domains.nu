# Auto-generated client for  v1.0.0
# Source: https://api.apis.guru/v2/specs/ote-godaddy.com/domains/1.0.0/openapi.json
# Auth: --token flag or $env._TOKEN

const CLIENT = {
  base_url: "http://localhost//api.ote-godaddy.com"
  token_env_var: "_TOKEN"
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

def base-url-completer [] { ["http://localhost//api.ote-godaddy.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/javascript" "application/json" "application/xml" "text/javascript" "text/xml"] }
def check-type-completer [] { ["FAST" "FULL" "fast" "full"] }
def entity-type-completer [] { ["ABORIGINAL" "ASSOCIATION" "CITIZEN" "CORPORATION" "EDUCATIONAL" "GOVERNMENT" "HOSPITAL" "INDIAN_BAND" "LEGAL_REPRESENTATIVE" "LIBRARY_ARCHIVE_MUSEUM" "MARK_REGISTERED" "MARK_TRADE" "PARTNERSHIP" "POLITICAL_PARTY" "RESIDENT_PERMANENT" "TRUST" "UNION"] }
def country-completer [] { ["AC" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KV" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SX" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TP" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW"] }
def type-completer [] { ["A" "AAAA" "CNAME" "MX" "NS" "SOA" "SRV" "TXT"] }
def type-completer-1 [] { ["A" "AAAA" "CNAME" "MX" "SRV" "TXT"] }
def type-completer-2 [] { ["MASKED" "REDIRECT_PERMANENT" "REDIRECT_TEMPORARY"] }
def type-completer-3 [] { ["AUTO_RENEWAL" "BACKORDER" "BACKORDER_PURCHASE" "EXPIRY" "PREMIUM" "PRIVACY_PURCHASE" "REDEEM" "REGISTER" "RENEW" "TRADE" "TRANSFER"] }
def type-completer-4 [] { ["AUTH_CODE_PURCHASE" "AUTH_CODE_REGENERATE" "BACKORDER_DELETE" "BACKORDER_PURCHASE" "BACKORDER_UPDATE" "DNSSEC_CREATE" "DNSSEC_DELETE" "DOMAIN_DELETE" "DOMAIN_UPDATE" "DOMAIN_UPDATE_CONTACTS" "DOMAIN_UPDATE_NAME_SERVERS" "MIGRATE" "PRIVACY_DELETE" "PRIVACY_PURCHASE" "REDEEM" "REGISTER" "RENEW" "RENEW_UNDO" "TRADE" "TRADE_CANCEL" "TRADE_PURCHASE" "TRADE_PURCHASE_AUTH_TEXT_MESSAGE" "TRADE_RESEND_AUTH_EMAIL" "TRANSFER" "TRANSFER_IN_CANCEL" "TRANSFER_OUT_ACCEPT" "TRANSFER_OUT_REJECT" "TRANSFER_OUT_REQUESTED" "TRANSIT"] }
def type-completer-5 [] { ["AUTH_CODE_PURCHASE" "AUTH_CODE_REGENERATE" "AUTO_RENEWAL" "BACKORDER_DELETE" "BACKORDER_PURCHASE" "BACKORDER_UPDATE" "DNSSEC_CREATE" "DNSSEC_DELETE" "DNS_VERIFICATION" "DOMAIN_DELETE" "DOMAIN_UPDATE" "DOMAIN_UPDATE_CONTACTS" "DOMAIN_UPDATE_NAME_SERVERS" "EXPIRY" "ICANN_VERIFICATION" "MIGRATE" "MIGRATE_IN" "PREMIUM" "PRIVACY_DELETE" "PRIVACY_PURCHASE" "REDEEM" "REGISTER" "RENEW" "RENEW_UNDO" "TRADE" "TRADE_CANCEL" "TRADE_PURCHASE" "TRADE_PURCHASE_AUTH_TEXT_MESSAGE" "TRADE_RESEND_AUTH_EMAIL" "TRANSFER" "TRANSFER_IN" "TRANSFER_IN_CANCEL" "TRANSFER_OUT" "TRANSFER_OUT_ACCEPT" "TRANSFER_OUT_REJECT" "TRANSFER_OUT_REQUESTED" "TRANSIT"] }
def status-completer [] { ["ACTIVE" "CANCELLED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    list: "table<authCode: string, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, renewable: bool, status: string, transferAwayEligibleAt: string, transferProtected: bool>"
    get-agreement: "table<agreementKey: string, content: string, title: string, url: string>"
    available: "record<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int>"
    available-bulk: "record<domains: table<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int>>"
    purchase: "record<currency: string, itemCount: int, orderId: int, total: int>"
    get-v1-domains-purchase-schema-tld: "record<id: string, models: record, properties: record, required: list<string>>"
    suggest: "table<domain: string>"
    tlds: "table<name: string, type: string>"
    get-v1-domains-domain: "record<authCode: string, contactAdmin: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: record<status: string>, realName: record<status: string>>>"
    purchase-privacy: "record<currency: string, itemCount: int, orderId: int, total: int>"
    record-get: "table<data: string, name: string, port: int, priority: int, protocol: string, service: string, ttl: int, type: string, weight: int>"
    renew: "record<currency: string, itemCount: int, orderId: int, total: int>"
    transfer-in: "record<currency: string, itemCount: int, orderId: int, total: int>"
    domains-forwards-get: "table<fqdn: string, mask: record<description: string, keywords: string, title: string>, type: string, url: string>"
    get-v2-customers-customer-id-domains-notifications: "record<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string>"
    get-v2-customers-customer-id-domains-notifications-opt-in: "table<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string>"
    get-v2-customers-customer-id-domains-notifications-schemas-type: "record<id: string, models: record, properties: record, required: list<string>>"
    get-v2-customers-customer-id-domains-domain: "record<actions: table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record, requestId: string, startedAt: string, status: string, type: string>, authCode: string, contacts: record<admin: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, billing: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, registrant: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, tech: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>>, createdAt: string, deletedAt: string, dnssecRecords: table<algorithm: string, digest: string, digestType: string, flags: string, keyTag: int, maxSignatureLife: int, publicKey: string>, domain: string, domainId: string, expirationProtected: bool, expiresAt: string, holdRegistrar: bool, hostnames: list<string>, locked: bool, modifiedAt: string, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, registryStatusCodes: list<string>, renewAuto: bool, renewDeadline: string, renewal: record<currency: string, price: int, renewable: bool>, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: string, icann: string, realName: string>>"
    get-v2-customers-customer-id-domains-domain-actions: "table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list, message: string>, requestId: string, startedAt: string, status: string, type: string>"
    get-v2-customers-customer-id-domains-domain-actions-type: "record<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list<record>, message: string>, requestId: string, startedAt: string, status: string, type: string>"
    get-v2-domains-maintenances: "record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, tlds: list<string>, type: string>"
    get-v2-domains-maintenances-maintenance-id: "record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, systems: table<impact: list, name: string>, tlds: list<string>, type: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list" "get-agreement" "available" "available-bulk" "contacts-validate" "purchase" "get-v1-domains-purchase-schema-tld" "validate" "suggest" "tlds" "cancel" "get-v1-domains-domain" "patch-v1-domains-domain" "update-contacts" "cancel-privacy" "purchase-privacy" "record-add" "record-replace" "record-replace-type" "record-delete-type-name" "record-get" "record-replace-type-name" "renew" "transfer-in" "verify-email" "domains-forwards-delete" "domains-forwards-get" "domains-forwards-post" "domains-forwards-put" "get-v2-customers-customer-id-domains-notifications" "get-v2-customers-customer-id-domains-notifications-opt-in" "put-v2-customers-customer-id-domains-notifications-opt-in" "get-v2-customers-customer-id-domains-notifications-schemas-type" "post-v2-customers-customer-id-domains-notifications-notification-id-acknowledge" "get-v2-customers-customer-id-domains-domain" "get-v2-customers-customer-id-domains-domain-actions" "delete-v2-customers-customer-id-domains-domain-actions-type" "get-v2-customers-customer-id-domains-domain-actions-type" "post-v2-customers-customer-id-domains-domain-redeem" "post-v2-customers-customer-id-domains-domain-transfer-out" "get-v2-domains-maintenances" "get-v2-domains-maintenances-maintenance-id" "commands"] | sort) } | get name | first)
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

# Retrieve a list of Domains for the specified Shopper
#
# GET /v1/domains
# Returns: table<authCode: string, contactAdmin: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, renewable: bool, status: string, transferAwayEligibleAt: string, transferProtected: bool>
# operationId: list
export def "list" [
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
  --statuses: list<string> # Only include results with `status` value in the specified set
  --status-groups: list<string> # Only include results with `status` value in any of the specified groups
  --limit: int # Maximum number of domains to return
  --marker: string # Marker Domain to use as the offset in results
  --includes: list<string> # Optional details to be included in the response
  --modified-date: string # Only include results that have been modified since the specified date (format: iso-datetime)
  --x-shopper-id: string # Shopper ID whose domains are to be retrieved
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains"
    query: [{name: statuses, var: statuses, style: csv}, {name: statusGroups, var: status_groups, style: csv}, {name: limit, var: limit}, {name: marker, var: marker}, {name: includes, var: includes, style: csv}, {name: modifiedDate, var: modified_date}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    statuses: $statuses, status_groups: $status_groups, limit: $limit, marker: $marker, includes: $includes, modified_date: $modified_date, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the legal agreement(s) required to purchase the specified TLD and add-ons
#
# GET /v1/domains/agreements
# Returns: table<agreementKey: string, content: string, title: string, url: string>
# operationId: getAgreement
export def "get-agreement" [
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
  --tlds: list<string> # list of TLDs whose legal agreements are to be retrieved (required)
  --privacy: oneof<nothing, bool> # Whether or not privacy has been requested (required)
  --for-transfer: oneof<nothing, bool> # Whether or not domain tranfer has been requested
  --x-market-id: string # Unique identifier of the Market used to retrieve/translate Legal Agreements (format: bcp-47, default: en-US)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains/agreements"
    query: [{name: tlds, var: tlds, style: csv, required: true}, {name: privacy, var: privacy, required: true}, {name: forTransfer, var: for_transfer}]
    header: [{name: X-Market-Id, var: x_market_id}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    tlds: $tlds, privacy: $privacy, for_transfer: $for_transfer, x_market_id: $x_market_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Determine whether or not the specified domain is available for purchase
#
# GET /v1/domains/available
# Returns: record<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int>
# operationId: available
export def "available" [
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
  --domain: string # Domain name whose availability is to be checked (required)
  --check-type: string@check-type-completer # Optimize for time ('FAST') or accuracy ('FULL') (default: FAST)
  --for-transfer: oneof<nothing, bool> # Whether or not to include domains available for transfer. If set to True, checkType is ignored (default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains/available"
    query: [{name: domain, var: domain, required: true}, {name: checkType, var: check_type}, {name: forTransfer, var: for_transfer}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, check_type: $check_type, for_transfer: $for_transfer
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Determine whether or not the specified domains are available for purchase
#
# POST /v1/domains/available
# Returns: record<domains: table<available: bool, currency: string, definitive: bool, domain: string, period: int, price: int>>
# operationId: availableBulk
export def "available-bulk" [
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
  --check-type: string@check-type-completer # Optimize for time ('FAST') or accuracy ('FULL') (default: FAST)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains/available"
    query: [{name: checkType, var: check_type}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200, 203]
    auth: bearer
  } {
    check_type: $check_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate the request body using the Domain Contact Validation Schema for specified domains.
#
# POST /v1/domains/contacts/validate
# operationId: ContactsValidate
export def "contacts-validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --market-id: string # MarketId in which the request is being made, and for which responses should be localized (format: bcp-47, default: en-US)
  --x-private-label-id: int # PrivateLabelId to operate as, if different from JWT (default: 1)
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-presence: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domains: list<string> # An array of domain names to be validated against. Alternatively, you can specify the extracted tlds. However, full domain names are required if the tld is `uk`
  --entity-type: string@entity-type-completer # Canadian Presence Requirement (CA)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/domains/contacts/validate"
    query: [{name: marketId, var: market_id}]
    header: [{name: X-Private-Label-Id, var: x_private_label_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactAdmin, var: contact_admin}, {name: contactBilling, var: contact_billing}, {name: contactPresence, var: contact_presence}, {name: contactRegistrant, var: contact_registrant}, {name: contactTech, var: contact_tech}, {name: domains, var: domains}, {name: entityType, var: entity_type}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    market_id: $market_id, x_private_label_id: $x_private_label_id, contact_admin: $contact_admin, contact_billing: $contact_billing, contact_presence: $contact_presence, contact_registrant: $contact_registrant, contact_tech: $contact_tech, domains: $domains, entity_type: $entity_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase and register the specified Domain
#
# POST /v1/domains/purchase
# Returns: record<currency: string, itemCount: int, orderId: int, total: int>
# operationId: purchase
export def "purchase" [
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
  --x-shopper-id: string # The Shopper for whom the domain should be purchased
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domain: string # For internationalized domain names with non-ascii characters, the domain name is converted to punycode before format and pattern validation rules are checked (format: domain)
  --name-servers: list<string>
  --period: int # format: integer-positive, default: 1
  --privacy: oneof<nothing, bool> # default: false
  --renew-auto: oneof<nothing, bool> # default: true
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains/purchase"
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: consent, var: consent}, {name: contactAdmin, var: contact_admin}, {name: contactBilling, var: contact_billing}, {name: contactRegistrant, var: contact_registrant}, {name: contactTech, var: contact_tech}, {name: domain, var: domain}, {name: nameServers, var: name_servers}, {name: period, var: period}, {name: privacy, var: privacy}, {name: renewAuto, var: renew_auto}]}
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    x_shopper_id: $x_shopper_id, consent: $consent, contact_admin: $contact_admin, contact_billing: $contact_billing, contact_registrant: $contact_registrant, contact_tech: $contact_tech, domain: $domain, name_servers: $name_servers, period: $period, privacy: $privacy, renew_auto: $renew_auto
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieve the schema to be submitted when registering a Domain for the specified TLD
#
# GET /v1/domains/purchase/schema/{tld}
# Returns: record<id: string, models: record, properties: record, required: list<string>>
# operationId: schema
export def "get-v1-domains-purchase-schema-tld" [
  tld: string
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
    path: "/v1/domains/purchase/schema/{tld}"
    path_params: [{name: tld, var: tld}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    tld: $tld
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Validate the request body using the Domain Purchase Schema for the specified TLD
#
# POST /v1/domains/purchase/validate
# operationId: validate
export def "validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  domain: string # For internationalized domain names with non-ascii characters, the domain name is converted to punycode before format and pattern validation rules are checked (format: domain)
  --name-servers: list<string>
  --period: int # format: integer-positive, default: 1
  --privacy: oneof<nothing, bool> # default: false
  --renew-auto: oneof<nothing, bool> # default: true
]: any -> any {
  $in | http-request {
    method: post
    path: "/v1/domains/purchase/validate"
    body: {content_type: "application/json", kind: json, fields: [{name: consent, var: consent}, {name: contactAdmin, var: contact_admin}, {name: contactBilling, var: contact_billing}, {name: contactRegistrant, var: contact_registrant}, {name: contactTech, var: contact_tech}, {name: domain, var: domain}, {name: nameServers, var: name_servers}, {name: period, var: period}, {name: privacy, var: privacy}, {name: renewAuto, var: renew_auto}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    consent: $consent, contact_admin: $contact_admin, contact_billing: $contact_billing, contact_registrant: $contact_registrant, contact_tech: $contact_tech, domain: $domain, name_servers: $name_servers, period: $period, privacy: $privacy, renew_auto: $renew_auto
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Suggest alternate Domain names based on a seed Domain, a set of keywords, or the shopper's purchase history
#
# GET /v1/domains/suggest
# Returns: table<domain: string>
# operationId: suggest
export def "suggest" [
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
  --query: string # Domain name or set of keywords for which alternative domain names will be suggested
  --country: string@country-completer # Two-letter ISO country code to be used as a hint for target region NOTE: These are sample values, there are many more (http://www.iso.org/iso/country_codes.htm) (format: iso-country-code)
  --city: string # Name of city to be used as a hint for target region (format: city-name)
  --sources: list<string> # Sources to be queried CC_TLD - Varies the TLD using Country Codes EXTENSION - Varies the TLD KEYWORD_SPIN - Identifies keywords and then rotates each one PREMIUM - Includes variations with premium prices
  --tlds: list<string> # Top-level domains to be included in suggestions NOTE: These are sample values, there are many more (http://www.godaddy.com/tlds/gtld.aspx#domain_search_form)
  --length-max: int # Maximum length of second-level domain
  --length-min: int # Minimum length of second-level domain
  --limit: int # Maximum number of suggestions to return
  --wait-ms: int # Maximum amount of time, in milliseconds, to wait for responses If elapses, return the results compiled up to that point (format: integer-positive, default: 1000)
  --x-shopper-id: string # Shopper ID for which the suggestions are being generated
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains/suggest"
    query: [{name: query, var: query}, {name: country, var: country}, {name: city, var: city}, {name: sources, var: sources, style: csv}, {name: tlds, var: tlds, style: csv}, {name: lengthMax, var: length_max}, {name: lengthMin, var: length_min}, {name: limit, var: limit}, {name: waitMs, var: wait_ms}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    query: $query, country: $country, city: $city, sources: $sources, tlds: $tlds, length_max: $length_max, length_min: $length_min, limit: $limit, wait_ms: $wait_ms, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Retrieves a list of TLDs supported and enabled for sale
#
# GET /v1/domains/tlds
# Returns: table<name: string, type: string>
# operationId: tlds
export def "tlds" [
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
    path: "/v1/domains/tlds"
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Cancel a purchased domain
#
# DELETE /v1/domains/{domain}
# operationId: cancel
export def "cancel" [
  domain: string
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
    path: "/v1/domains/{domain}"
    path_params: [{name: domain, var: domain}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve details for the specified Domain
#
# GET /v1/domains/{domain}
# Returns: record<authCode: string, contactAdmin: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactBilling: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactRegistrant: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, contactTech: record<addressMailing: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, email: string, fax: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string>, createdAt: string, deletedAt: string, domain: string, domainId: float, expirationProtected: bool, expires: string, exposeWhois: bool, holdRegistrar: bool, locked: bool, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, renewAuto: bool, renewDeadline: string, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: record<status: string>, realName: record<status: string>>>
# operationId: get
export def "get-v1-domains-domain" [
  domain: string
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
  --x-shopper-id: string # Shopper ID expected to own the specified domain
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains/{domain}"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200, 203]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Update details for the specified Domain
#
# PATCH /v1/domains/{domain}
# operationId: update
export def "patch-v1-domains-domain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom Domain is to be updated. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --expose-whois: oneof<nothing, bool> # Whether or not the domain contact details should be shown in the WHOIS
  --locked: oneof<nothing, bool> # Whether or not the domain should be locked to prevent transfers
  --name-servers: list # Fully-qualified domain names for Name Servers to associate with the domain
  --renew-auto: oneof<nothing, bool> # Whether or not the domain should be configured to automatically renew
  --subaccount-id: string # Reseller subaccount shopperid who can manage the domain
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/domains/{domain}"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: consent, var: consent}, {name: exposeWhois, var: expose_whois}, {name: locked, var: locked}, {name: nameServers, var: name_servers}, {name: renewAuto, var: renew_auto}, {name: subaccountId, var: subaccount_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, consent: $consent, expose_whois: $expose_whois, locked: $locked, name_servers: $name_servers, renew_auto: $renew_auto, subaccount_id: $subaccount_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update domain
#
# PATCH /v1/domains/{domain}/contacts
# operationId: updateContacts
export def "update-contacts" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom domain contacts are to be updated. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  contact_registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/domains/{domain}/contacts"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactAdmin, var: contact_admin}, {name: contactBilling, var: contact_billing}, {name: contactRegistrant, var: contact_registrant}, {name: contactTech, var: contact_tech}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, contact_admin: $contact_admin, contact_billing: $contact_billing, contact_registrant: $contact_registrant, contact_tech: $contact_tech
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a privacy cancellation request for the given domain
#
# DELETE /v1/domains/{domain}/privacy
# operationId: cancelPrivacy
export def "cancel-privacy" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID of the owner of the domain
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/domains/{domain}/privacy"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase privacy for a specified domain
#
# POST /v1/domains/{domain}/privacy/purchase
# Returns: record<currency: string, itemCount: int, orderId: int, total: int>
# operationId: purchasePrivacy
export def "purchase-privacy" [
  domain: string
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
  --x-shopper-id: string # Shopper ID of the owner of the domain
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains/{domain}/privacy/purchase"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: consent, var: consent}]}
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, consent: $consent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add the specified DNS Records to the specified Domain
#
# PATCH /v1/domains/{domain}/records
# operationId: recordAdd
export def "record-add" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  $in | http-request {
    method: patch
    path: "/v1/domains/{domain}/records"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace all DNS Records for the specified Domain
#
# PUT /v1/domains/{domain}/records
# operationId: recordReplace
export def "record-replace" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/domains/{domain}/records"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace all DNS Records for the specified Domain with the specified Type
#
# PUT /v1/domains/{domain}/records/{type}
# operationId: recordReplaceType
export def "record-replace-type" [
  domain: string
  type: string@type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/domains/{domain}/records/{type}"
    path_params: [{name: domain, var: domain}, {name: type, var: type}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, type: $type, x_shopper_id: $x_shopper_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete all DNS Records for the specified Domain with the specified Type and Name
#
# DELETE /v1/domains/{domain}/records/{type}/{name}
# operationId: recordDeleteTypeName
export def "record-delete-type-name" [
  domain: string
  type: string@type-completer-1
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
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/domains/{domain}/records/{type}/{name}"
    path_params: [{name: domain, var: domain}, {name: type, var: type}, {name: name, var: name}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain: $domain, type: $type, name: $name, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve DNS Records for the specified Domain, optionally with the specified Type and/or Name
#
# GET /v1/domains/{domain}/records/{type}/{name}
# Returns: table<data: string, name: string, port: int, priority: int, protocol: string, service: string, ttl: int, type: string, weight: int>
# operationId: recordGet
export def "record-get" [
  domain: string
  type: string@type-completer
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
  --offset: int # Number of results to skip for pagination
  --limit: int # Maximum number of items to return
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v1/domains/{domain}/records/{type}/{name}"
    path_params: [{name: domain, var: domain}, {name: type, var: type}, {name: name, var: name}]
    query: [{name: offset, var: offset}, {name: limit, var: limit}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, type: $type, name: $name, offset: $offset, limit: $limit, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Replace all DNS Records for the specified Domain with the specified Type and Name
#
# PUT /v1/domains/{domain}/records/{type}/{name}
# operationId: recordReplaceTypeName
export def "record-replace-type-name" [
  domain: string
  type: string@type-completer
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
  --x-shopper-id: string # Shopper ID which owns the domain. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/v1/domains/{domain}/records/{type}/{name}"
    path_params: [{name: domain, var: domain}, {name: type, var: type}, {name: name, var: name}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, type: $type, name: $name, x_shopper_id: $x_shopper_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Renew the specified Domain
#
# POST /v1/domains/{domain}/renew
# Returns: record<currency: string, itemCount: int, orderId: int, total: int>
# operationId: renew
export def "renew" [
  domain: string
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
  --x-shopper-id: string # Shopper for whom Domain is to be renewed. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
  --period: int # Number of years to extend the Domain. Must not exceed maximum for TLD. When omitted, defaults to `period` specified during original purchase (format: integer-positive)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains/{domain}/renew"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: period, var: period}]}
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, period: $period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Purchase and start or restart transfer process
#
# POST /v1/domains/{domain}/transfer
# Returns: record<currency: string, itemCount: int, orderId: int, total: int>
# operationId: transferIn
export def "transfer-in" [
  domain: string
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
  --x-shopper-id: string # The Shopper to whom the domain should be transfered
  auth_code: string # Authorization code from registrar for transferring a domain
  consent: any # shape: {agreedAt: string, agreedBy: string, agreementKeys: list<string>}
  --contact-admin: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-billing: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-registrant: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --contact-tech: any # shape: {addressMailing: any, email: string, fax?: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, organization?: string, phone: string}
  --period: int # Can be more than 1 but no more than 10 years total including current registration length (format: integer-positive, default: 1)
  --privacy: oneof<nothing, bool> # Whether or not privacy has been requested (default: false)
  --renew-auto: oneof<nothing, bool> # Whether or not the domain should be configured to automatically renew (default: true)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/domains/{domain}/transfer"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: authCode, var: auth_code}, {name: consent, var: consent}, {name: contactAdmin, var: contact_admin}, {name: contactBilling, var: contact_billing}, {name: contactRegistrant, var: contact_registrant}, {name: contactTech, var: contact_tech}, {name: period, var: period}, {name: privacy, var: privacy}, {name: renewAuto, var: renew_auto}]}
    accept: ["application/javascript", "application/json", "application/xml", "text/javascript", "text/xml"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id, auth_code: $auth_code, consent: $consent, contact_admin: $contact_admin, contact_billing: $contact_billing, contact_registrant: $contact_registrant, contact_tech: $contact_tech, period: $period, privacy: $privacy, renew_auto: $renew_auto
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Re-send Contact E-mail Verification for specified Domain
#
# POST /v1/domains/{domain}/verifyRegistrantEmail
# operationId: verifyEmail
export def "verify-email" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-shopper-id: string # Shopper for whom domain contact e-mail should be verified. NOTE: This is only required if you are a Reseller managing a domain purchased outside the scope of your reseller account. For instance, if you're a Reseller, but purchased a Domain via http://www.godaddy.com
]: nothing -> any {
  http-request {
    method: post
    path: "/v1/domains/{domain}/verifyRegistrantEmail"
    path_params: [{name: domain, var: domain}]
    header: [{name: X-Shopper-Id, var: x_shopper_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain: $domain, x_shopper_id: $x_shopper_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a forwarding cancellation request for the given fqdn
#
# DELETE /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsDelete
export def "domains-forwards-delete" [
  customer_id: string
  fqdn: string
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
    path: "/v2/customers/{customerId}/domains/forwards/{fqdn}"
    path_params: [{name: customerId, var: customer_id}, {name: fqdn, var: fqdn}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, fqdn: $fqdn
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the forwarding information for the given fqdn
#
# GET /v2/customers/{customerId}/domains/forwards/{fqdn}
# Returns: table<fqdn: string, mask: record<description: string, keywords: string, title: string>, type: string, url: string>
# operationId: domainsForwardsGet
export def "domains-forwards-get" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-subs: oneof<nothing, bool> # Optionally include all sub domains if the fqdn specified is a domain and not a sub domain.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/forwards/{fqdn}"
    path_params: [{name: customerId, var: customer_id}, {name: fqdn, var: fqdn}]
    query: [{name: includeSubs, var: include_subs}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, fqdn: $fqdn, include_subs: $include_subs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new forwarding configuration for the given FQDN
#
# POST /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsPost
export def "domains-forwards-post" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: any # shape: {description?: string, keywords?: string, title?: string}
  type: string@type-completer-2 # The type of fowarding to implementMASKED - Prevents the forwarded domain or subdomain URL from displaying in the browser's address bar.REDIRECT_PERMANENT* - Redirects to the url you specified in the forwardTo field using a `301 Moved Permanently` HTTP response. The HTTP 301 response code tells user-agents (including search engines) that the location has permanently moved.REDIRECT_TEMPORARY - Redirects to the url you specified in the forwardTo field using a `302 Found` HTTP response. The HTTP 302 response code tells user-agents (including search engines) that the location has temporarily moved. (default: REDIRECT_PERMANENT)
  url: string # Forwards http(s) traffic to this destination url (ex. http://www.somedomain.com/) (format: url)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/customers/{customerId}/domains/forwards/{fqdn}"
    path_params: [{name: customerId, var: customer_id}, {name: fqdn, var: fqdn}]
    body: {content_type: "application/json", kind: json, fields: [{name: mask, var: mask}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, fqdn: $fqdn, mask: $mask, type: $type, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the forwarding information for the given fqdn
#
# PUT /v2/customers/{customerId}/domains/forwards/{fqdn}
# operationId: domainsForwardsPut
export def "domains-forwards-put" [
  customer_id: string
  fqdn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mask: any # shape: {description?: string, keywords?: string, title?: string}
  type: string@type-completer-2 # The type of fowarding to implementMASKED - Prevents the forwarded domain or subdomain URL from displaying in the browser's address bar.REDIRECT_PERMANENT* - Redirects to the url you specified in the forwardTo field using a `301 Moved Permanently` HTTP response. The HTTP 301 response code tells user-agents (including search engines) that the location has permanently moved.REDIRECT_TEMPORARY - Redirects to the url you specified in the forwardTo field using a `302 Found` HTTP response. The HTTP 302 response code tells user-agents (including search engines) that the location has temporarily moved. (default: REDIRECT_PERMANENT)
  url: string # Forwards http(s) traffic to this destination url (ex. http://www.somedomain.com/) (format: url)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v2/customers/{customerId}/domains/forwards/{fqdn}"
    path_params: [{name: customerId, var: customer_id}, {name: fqdn, var: fqdn}]
    body: {content_type: "application/json", kind: json, fields: [{name: mask, var: mask}, {name: type, var: type}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, fqdn: $fqdn, mask: $mask, type: $type, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the next domain notification
#
# GET /v2/customers/{customerId}/domains/notifications
# Returns: record<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string>
export def "get-v2-customers-customer-id-domains-notifications" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/notifications"
    path_params: [{name: customerId, var: customer_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of notification types that are opted in
#
# GET /v2/customers/{customerId}/domains/notifications/optIn
# Returns: table<addedAt: string, metadata: record, notificationId: string, requestId: string, resource: string, resourceType: string, status: string, type: string>
export def "get-v2-customers-customer-id-domains-notifications-opt-in" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/notifications/optIn"
    path_params: [{name: customerId, var: customer_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Opt in to recieve notifications for the submitted notification types
#
# PUT /v2/customers/{customerId}/domains/notifications/optIn
export def "put-v2-customers-customer-id-domains-notifications-opt-in" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --types: list<string> # The notification types that should be opted in (required)
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  http-request {
    method: put
    path: "/v2/customers/{customerId}/domains/notifications/optIn"
    path_params: [{name: customerId, var: customer_id}]
    query: [{name: types, var: types, style: csv, required: true}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, types: $types, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the schema for the notification data for the specified notification type
#
# GET /v2/customers/{customerId}/domains/notifications/schemas/{type}
# Returns: record<id: string, models: record, properties: record, required: list<string>>
export def "get-v2-customers-customer-id-domains-notifications-schemas-type" [
  customer_id: string
  type: string@type-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/notifications/schemas/{type}"
    path_params: [{name: customerId, var: customer_id}, {name: type, var: type}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, type: $type, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Acknowledge a domain notification
#
# POST /v2/customers/{customerId}/domains/notifications/{notificationId}/acknowledge
export def "post-v2-customers-customer-id-domains-notifications-notification-id-acknowledge" [
  customer_id: string
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customers/{customerId}/domains/notifications/{notificationId}/acknowledge"
    path_params: [{name: customerId, var: customer_id}, {name: notificationId, var: notification_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, notification_id: $notification_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve details for the specified Domain
#
# GET /v2/customers/{customerId}/domains/{domain}
# Returns: record<actions: table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record, requestId: string, startedAt: string, status: string, type: string>, authCode: string, contacts: record<admin: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, billing: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, registrant: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>, tech: record<_createdAt: string, _deleted: bool, _modifiedAt: string, _revision: int, addressMailing: record, contactId: string, email: string, encoding: string, exposeWhois: bool, fax: string, jobTitle: string, metadata: record, nameFirst: string, nameLast: string, nameMiddle: string, organization: string, phone: string, tlds: list>>, createdAt: string, deletedAt: string, dnssecRecords: table<algorithm: string, digest: string, digestType: string, flags: string, keyTag: int, maxSignatureLife: int, publicKey: string>, domain: string, domainId: string, expirationProtected: bool, expiresAt: string, holdRegistrar: bool, hostnames: list<string>, locked: bool, modifiedAt: string, nameServers: list<string>, privacy: bool, registrarCreatedAt: string, registryStatusCodes: list<string>, renewAuto: bool, renewDeadline: string, renewal: record<currency: string, price: int, renewable: bool>, status: string, subaccountId: string, transferAwayEligibleAt: string, transferProtected: bool, verifications: record<domainName: string, icann: string, realName: string>>
export def "get-v2-customers-customer-id-domains-domain" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list<string> # Optional details to be included in the response
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/{domain}"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}]
    query: [{name: includes, var: includes, style: csv}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200, 203]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, includes: $includes, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a list of the most recent actions for the specified domain
#
# GET /v2/customers/{customerId}/domains/{domain}/actions
# Returns: table<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list, message: string>, requestId: string, startedAt: string, status: string, type: string>
export def "get-v2-customers-customer-id-domains-domain-actions" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/{domain}/actions"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel the most recent user action for the specified domain
#
# DELETE /v2/customers/{customerId}/domains/{domain}/actions/{type}
export def "delete-v2-customers-customer-id-domains-domain-actions-type" [
  customer_id: string
  domain: string
  type: string@type-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  http-request {
    method: delete
    path: "/v2/customers/{customerId}/domains/{domain}/actions/{type}"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}, {name: type, var: type}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, type: $type, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves the most recent action for the specified domain
#
# GET /v2/customers/{customerId}/domains/{domain}/actions/{type}
# Returns: record<completedAt: string, createdAt: string, modifiedAt: string, origination: string, reason: record<code: string, fields: list<record>, message: string>, requestId: string, startedAt: string, status: string, type: string>
export def "get-v2-customers-customer-id-domains-domain-actions-type" [
  customer_id: string
  domain: string
  type: string@type-completer-5
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/customers/{customerId}/domains/{domain}/actions/{type}"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}, {name: type, var: type}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, type: $type, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Purchase a restore for the given domain to bring it out of redemption
#
# POST /v2/customers/{customerId}/domains/{domain}/redeem
export def "post-v2-customers-customer-id-domains-domain-redeem" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
  consent: any # shape: {agreedAt: string, agreedBy: string, currency: string, fee: int, price: int}
]: any -> any {
  $in | http-request {
    method: post
    path: "/v2/customers/{customerId}/domains/{domain}/redeem"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}]
    header: [{name: X-Request-Id, var: x_request_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: consent, var: consent}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, x_request_id: $x_request_id, consent: $consent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Initiate transfer out to another registrar for a .uk domain.
#
# POST /v2/customers/{customerId}/domains/{domain}/transferOut
export def "post-v2-customers-customer-id-domains-domain-transfer-out" [
  customer_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registrar: string # Registrar tag to push transfer to (required)
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> any {
  http-request {
    method: post
    path: "/v2/customers/{customerId}/domains/{domain}/transferOut"
    path_params: [{name: customerId, var: customer_id}, {name: domain, var: domain}]
    query: [{name: registrar, var: registrar, required: true}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    customer_id: $customer_id, domain: $domain, registrar: $registrar, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve a list of upcoming system Maintenances
#
# GET /v2/domains/maintenances
# Returns: record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, tlds: list<string>, type: string>
export def "get-v2-domains-maintenances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Only include results with the selected `status` value. Returns all results if omittedACTIVE - The upcoming maintenance is active.CANCELLED - The upcoming maintenance has been cancelled.
  --modified-at-after: string # Only include results with `modifiedAt` after the supplied date (format: iso-datetime)
  --starts-at-after: string # Only include results with `startsAt` after the supplied date (format: iso-datetime)
  --limit: int # Maximum number of results to return (default: 100)
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domains/maintenances"
    query: [{name: status, var: status}, {name: modifiedAtAfter, var: modified_at_after}, {name: startsAtAfter, var: starts_at_after}, {name: limit, var: limit}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status: $status, modified_at_after: $modified_at_after, starts_at_after: $starts_at_after, limit: $limit, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieve the details for an upcoming system Maintenances
#
# GET /v2/domains/maintenances/{maintenanceId}
# Returns: record<createdAt: string, endsAt: string, environment: string, maintenanceId: string, modifiedAt: string, reason: string, startsAt: string, status: string, summary: string, systems: table<impact: list, name: string>, tlds: list<string>, type: string>
export def "get-v2-domains-maintenances-maintenance-id" [
  maintenance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # A client provided identifier for tracking this request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v2/domains/maintenances/{maintenanceId}"
    path_params: [{name: maintenanceId, var: maintenance_id}]
    header: [{name: X-Request-Id, var: x_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    maintenance_id: $maintenance_id, x_request_id: $x_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
