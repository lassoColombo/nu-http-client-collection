# Auto-generated client for smart-me v1
# Source: https://api.apis.guru/v2/specs/smart-me.com/v1/openapi.json
# Auth: --token flag or $env.SMART_ME_TOKEN

const CLIENT = {
  base_url: "https://smart-me.com:443"
  token_env_var: "SMART_ME_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: basic, in: header, header_name: Authorization, prefix: Basic}
    {name: basic-credentials, in: header, header_name: Authorization, prefix: Basic, base64: true}
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

def base-url-completer [] { ["https://smart-me.com:443"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def device-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def meter-sub-type-completer [] { ["MeterSubTypeChargingStation" "MeterSubTypeCold" "MeterSubTypeElectricity" "MeterSubTypeElectricityHeat" "MeterSubTypeGas" "MeterSubTypeHeat" "MeterSubTypeTemperature" "MeterSubTypeUnknown" "MeterSubTypeVirtualBattery" "MeterSubTypeWater"] }
def meter-energy-type-completer [] { ["MeterTypeAllMeters" "MeterTypeCompressedAir" "MeterTypeCustomDevice" "MeterTypeElectricity" "MeterTypeGas" "MeterTypeHCA" "MeterTypeHeat" "MeterTypeMBusGateway" "MeterTypeRS485Gateway" "MeterTypeSolarLog" "MeterTypeTemperature" "MeterTypeUnknown" "MeterTypeVirtualMeter" "MeterTypeWMBusGateway" "MeterTypeWater"] }
def registration-type-completer [] { ["Disabled" "SingleMeterRegistration" "UserRegistration"] }
def dns-update-state-completer [] { ["DnsUpdateInternalIp" "DnsUpdatePublicIp" "NoUpdate"] }
def upload-interval-completer [] { ["UploadInterval_10s" "UploadInterval_12h" "UploadInterval_15min" "UploadInterval_1s" "UploadInterval_24h" "UploadInterval_30min" "UploadInterval_30s" "UploadInterval_5min" "UploadInterval_5s" "UploadInterval_60min" "UploadInterval_60s" "UploadInterval_6h"] }
def permission-level-completer [] { ["SelectedFolderAndSubfoldersMeters" "SelectedFolderOnly"] }
def folder-type-completer [] { ["Car" "ChargingStation" "Coffee" "ElecticityFolder" "Factory" "Folder" "Food" "GasFolder" "GridPhotovoltaicPowerSystem" "HeatFolder" "House" "Ice" "Light" "Location" "Machine" "Meter" "Office" "Sofa" "Sun" "TemperatureFolder" "Trash" "User" "VirtualMeter" "WaterFolder"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    access-token-put: "string"
    account-login: "record"
    post-api-account-login: "record"
    actions-get: "table<ActionType: string, MaxValue: float, MinValue: float, Name: string, ObisCode: string>"
    additional-device-information-get: "record<AdditionalMeterSerialNumber: string, FirmwareVersion: int, HardwareVersion: int, ID: string, NetworkConnection: string, NetworkConnectionRSSI: int>"
    custom-device-get: "table<Id: string, Name: string, Serial: int, ValueDate: string, Values: list<record>>"
    custom-device-post: "record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>"
    get-api-custom-device-id: "record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>"
    device-by-serial-get: "record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    devices-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    devices-post: "record<ActivePower: float, CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingT1: float, CounterReadingT2: float, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    get-api-devices-id: "record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    devices-put: "record"
    devices-by-energy-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    devices-by-sub-type-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    folder-get: "record<ElectricityCounterValue: float, ElectricityPower: float, GasCounterValue: float, GasFlowRate: float, HeatCounterValue: float, HeatPower: float, WaterCounterValue: float, WaterFlowRate: float>"
    folder-menu-get: "record<BrowserTimeZoneName: string, BrowserUtcTime: string, Items: table<AutoExportSettings: record, Children: list, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>>"
    health-get: "record"
    m-bus-post: "record"
    meter-folder-information-get: "record<CommunicationModuleFirmwareVersion: int, CommunicationModuleHardwareVersion: int, FirmwareVersion: int, HardwareVersion: int, InputInformations: table<Name: string, Number: int>, IsFolder: bool, Name: string, OutputInformations: table<ActionType: string, Name: string, Number: int, ObisCode: string>>"
    meter-values-get: "record<CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingExportT3: float, CounterReadingExportT4: float, CounterReadingImport: float, CounterReadingImportT1: float, CounterReadingImportT2: float, CounterReadingImportT3: float, CounterReadingImportT4: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Date: string, Id: string, Serial: int>"
    register-for-realtime-api-get: "table<ApiUrl: string, BasicAuthPassword: string, BasicAuthUsername: string, Id: string, MeterId: string, RegistrationType: string, SerialNumber: string>"
    smart-me-device-configuration-get: "record<DeviceEncryptionKey: string, DevicePinCode: string, DnsUpdateState: string, EnableModbusTcp: bool, Id: string, InputConfiguration: table<Name: string, Number: int, OffText: string, OnText: string, Type: string>, OutputConfiguration: table<DigitalOutputNoConnectionAction: string, Name: string, Number: int, S0PulseValue: string, Type: string>, ShowReactiveEnergy: bool, SwitchConfiguration: table<CanSwitchOff: bool, Number: int>, UploadInterval: string>"
    sub-user-get: "record<AccessEndDate: string, AccessTimeStartDate: string, Email: string, Id: string, NewPassword: string, PermissionLevel: string, Username: string>"
    user-delete: "record"
    user-get: "record<ChildUsers: list<any>, Email: string, Id: int, IdAsString: string, IsAdmin: bool, Permissions: list<string>, Username: string>"
    values-get: "record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>"
    values-in-past-get: "record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>"
    values-in-past-multiple-get: "table<Date: string, DeviceId: string, Values: list<record>>"
    virtual-billing-meter-active-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    virtual-billing-meter-active-post: "record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    virtual-billing-meter-deactivate-post: "record"
    virtual-billing-meters-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    virtual-meter-calculate-formula-get: "record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    virtual-tariff-get: "table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>"
    get-api-virtual-tariff-id: "record<Date: string, FolderId: string, Name: string, VirtualTariffs: table<Factor: float, Id: string, Name: string, Type: string, Unit: string, Value: float>>"
    virtual-tariff-consumption-get: "table<Consumption: float, Currency: string, Name: string, Price: float, TariffType: string>"
    virtual-tariffs-for-property-get: "table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>"
    virtual-tariffs-status-for-property-get: "string"
    folder-settings-get: "record<Description: string, Enable: bool, FolderType: string, Name: string, ParentFolderId: string, SerialNumber: int, UseableForVirtualBillingMeters: bool, ValueCorrection: float, ValueCorrectionParentFolder: float, VisualizationName: string>"
    folder-settings-post: "record<AutoExportSettings: record<ExportFormat: string, ExportInterval: string, MeterPointId: string, UploadType: string>, Children: list<any>, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>"
    o-auth-authorize: "record"
    post-api-oauth-authorize: "record"
    pico-get: "table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>"
    pico-charging-get: "record<ActiveChargingEnergy: float, ActiveChargingPower: float, ConnectionMode: string, Duration: int, LastWarningOrError: string, LastWarningOrErrorMessage: string, LastWarningOrErrorTime: string, LoadSheddingState: string, LoadmanagementGroupName: string, MaxAllowedChargingCurrent: int, MaxDynamicCurrent: int, MaxLoadmanagementGroupCurrent: int, MaxStationCurrent: int, MinStationCurrent: int, State: string, ValueDate: string>"
    pico-charging-history-get: "table<Duration: int, EnergyUsed: float, StartTime: string>"
    get-api-pico-loadmanagementgroup: "table<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>"
    pico-loadmanagement-set-dynamic-current-post: "record"
    pico-loadmanagement-group-get: "record<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>"
    pico-settings-get: "record<AuthenticationType: string, CarIdDetection: bool, DisplayBrightness: string, DnsName: string, FixCableLockEnable: bool, IdleImageUrl: string, InternalIp: string, LoadmanagementGroupId: string, MaxCurrent: int, MinCurrent: int, ModbusTcp: bool, Name: string, SerialNumber: string>"
    pico-enable-fix-cable-lock-post: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["access-token-put" "account-login" "post-api-account-login" "actions-post" "actions-get" "additional-device-information-get" "custom-device-get" "custom-device-post" "get-api-custom-device-id" "device-by-serial-get" "devices-get" "devices-post" "get-api-devices-id" "devices-put" "devices-by-energy-get" "devices-by-sub-type-get" "fast-send-device-values-get" "folder-get" "folder-menu-get" "folder-menu-post" "health-get" "m-bus-post" "meter-folder-information-post" "meter-folder-information-get" "meter-values-get" "register-for-realtime-api-get" "register-for-realtime-api-post" "register-for-realtime-api-delete" "smart-me-device-configuration-post" "smart-me-device-configuration-get" "sub-user-post" "sub-user-delete" "sub-user-get" "user-delete" "user-get" "values-get" "values-in-past-get" "values-in-past-multiple-get" "virtual-billing-meter-active-get" "virtual-billing-meter-active-post" "virtual-billing-meter-deactivate-post" "virtual-billing-meters-get" "virtual-meter-calculate-formula-get" "virtual-tariff-get" "get-api-virtual-tariff-id" "virtual-tariff-consumption-get" "virtual-tariffs-for-property-get" "virtual-tariffs-status-for-property-get" "folder-assign-post" "folder-settings-delete" "folder-settings-get" "folder-settings-post" "user-to-folder-assign-delete" "user-to-folder-assign-post" "o-auth-authorize" "post-api-oauth-authorize" "pico-get" "pico-charging-get" "pico-charging-history-get" "get-api-pico-loadmanagementgroup" "pico-loadmanagement-set-dynamic-current-post" "pico-loadmanagement-group-get" "pico-settings-get" "pico-enable-fix-cable-lock-post" "commands"] | sort) } | get name | first)
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

# Creates a Access Token to write on a Card (e.g. NFC)
#
# PUT /api/AccessToken
# Returns: string
# operationId: AccessToken_Put
export def "access-token-put" [
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
  --card-id: int # The ID of the Card (format: int64)
  --user-id: int # The ID of the User. The credentials provided must have permission to edit the user. If no ID is provided, the user in the credentials is taken. (format: int64)
]: any -> any {
  $in | http-request {
    method: put
    path: "/api/AccessToken"
    body: {content_type: "application/json", kind: json, fields: [{name: CardId, var: card_id}, {name: UserId, var: user_id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    card_id: $card_id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET /api/Account/login
#
# Returns: record
# operationId: Account_Login
export def "account-login" [
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
    path: "/api/Account/login"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/Account/login
#
# Returns: record
export def "post-api-account-login" [
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
    method: post
    path: "/api/Account/login"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Set an action for the specified device.
#
# POST /api/Actions
# operationId: Actions_Post
export def "actions-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: list # List with all Actions for this device — item shape: {ObisCode?: string, Value?: float}
  --device-id: string # The ID of the Device
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/Actions"
    body: {content_type: "application/json", kind: json, fields: [{name: Actions, var: actions}, {name: DeviceID, var: device_id}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    actions: $actions, device_id: $device_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets all available Actions of a Device
#
# GET /api/Actions/{id}
# Returns: table<ActionType: string, MaxValue: float, MinValue: float, Name: string, ObisCode: string>
# operationId: Actions_Get
export def "actions-get" [
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
    path: "/api/Actions/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the additional information (e.g. Firmware Version) about a device.
#
# GET /api/AdditionalDeviceInformation/{id}
# Returns: record<AdditionalMeterSerialNumber: string, FirmwareVersion: int, HardwareVersion: int, ID: string, NetworkConnection: string, NetworkConnectionRSSI: int>
# operationId: AdditionalDeviceInformation_Get
export def "additional-device-information-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/AdditionalDeviceInformation/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Custom Devices
#
# GET /api/CustomDevice
# Returns: table<Id: string, Name: string, Serial: int, ValueDate: string, Values: list<record>>
# operationId: CustomDevice_Get
export def "custom-device-get" [
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
    path: "/api/CustomDevice"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or updates a Custom Device or updates it's values.
#
# POST /api/CustomDevice
# Returns: record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>
# operationId: CustomDevice_Post
export def "custom-device-post" [
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
  --id: string # The ID of the device
  --name: string # The Name of the Device
  --serial: int # The Serial number (format: int64)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --values: list # The Values of the custom Device — item shape: {Name?: string, Value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/CustomDevice"
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}, {name: Serial, var: serial}, {name: ValueDate, var: value_date}, {name: Values, var: values}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id, name: $name, serial: $serial, value_date: $value_date, values: $values
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Custom Device by it's ID
#
# GET /api/CustomDevice/{id}
# Returns: record<Id: string, Name: string, Serial: int, ValueDate: string, Values: table<Name: string, Value: float>>
export def "get-api-custom-device-id" [
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
    path: "/api/CustomDevice/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Device by it's Serial Number. The Serial is the part before the "-".
#
# GET /api/DeviceBySerial
# Returns: record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: DeviceBySerial_Get
export def "device-by-serial-get" [
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
  --serial: int # The Serial Number of the device (required, format: int64)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/DeviceBySerial"
    query: [{name: serial, var: serial, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    serial: $serial
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Devices
#
# GET /api/Devices
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: Devices_Get
export def "devices-get" [
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
    path: "/api/Devices"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or updates a Device or updates it's values.
#
# POST /api/Devices
# Returns: record<ActivePower: float, CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingT1: float, CounterReadingT2: float, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: Devices_Post
export def "devices-post" [
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
  --active-power: float # The Active Power or current flow rate. In kW or m3/h (format: double)
  --counter-reading: float # The Meter Counter Reading (Total Energy used) in kWh or m3. (format: double)
  --counter-reading-export: float # The Meter Counter Reading only export (format: double)
  --counter-reading-export-t1: float # The Meter Counter Reading only export (Tariff 1) (format: double)
  --counter-reading-export-t2: float # The Meter Counter Reading only export (Tariff 2) (format: double)
  --counter-reading-t1: float # The Meter Counter Reading Tariff 1 in kWh or m3. (format: double)
  --counter-reading-t2: float # The Meter Counter Reading Tariff 2 in kWh or m3. (format: double)
  --current: float # The Current (in A) (format: double)
  --current-l1: float # The Current Phase L1 (in A) (format: double)
  --current-l2: float # The Current Phase L2 (in A) (format: double)
  --current-l3: float # The Current Phase L3 (in A) (format: double)
  --device-energy-type: string@device-energy-type-completer # The Energy Type of this device
  --digital-input1: oneof<nothing, bool> # The digital input number 1
  --id: string # The ID of the device
  --meter-sub-type: string@meter-sub-type-completer # The Sub Type of this Meter.
  --name: string # The Name of the Device
  --power-factor: float # The Power Factor (cos phi). Range: 0 - 1 (format: double)
  --power-factor-l1: float # The Power Factor (cos phi) Phase L1. Range: 0 - 1 (format: double)
  --power-factor-l2: float # The Power Factor (cos phi) Phase L2. Range: 0 - 1 (format: double)
  --power-factor-l3: float # The Power Factor (cos phi) Phase L3. Range: 0 - 1 (format: double)
  --serial: int # The Serial number (format: int64)
  --temperature: float # The Temperature (in degree celsius) (format: double)
  --value-date: string # The Date of the Value (in UTC). If this is null the Server Time is used. (format: date-time)
  --voltage: float # The Voltage (in V) (format: double)
  --voltage-l1: float # The Voltage Phase L1 (in V) (format: double)
  --voltage-l2: float # The Voltage Phase L2 (in V) (format: double)
  --voltage-l3: float # The Voltage Phase L3 (in V) (format: double)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/Devices"
    body: {content_type: "application/json", kind: json, fields: [{name: ActivePower, var: active_power}, {name: CounterReading, var: counter_reading}, {name: CounterReadingExport, var: counter_reading_export}, {name: CounterReadingExportT1, var: counter_reading_export_t1}, {name: CounterReadingExportT2, var: counter_reading_export_t2}, {name: CounterReadingT1, var: counter_reading_t1}, {name: CounterReadingT2, var: counter_reading_t2}, {name: Current, var: current}, {name: CurrentL1, var: current_l1}, {name: CurrentL2, var: current_l2}, {name: CurrentL3, var: current_l3}, {name: DeviceEnergyType, var: device_energy_type}, {name: DigitalInput1, var: digital_input1}, {name: Id, var: id}, {name: MeterSubType, var: meter_sub_type}, {name: Name, var: name}, {name: PowerFactor, var: power_factor}, {name: PowerFactorL1, var: power_factor_l1}, {name: PowerFactorL2, var: power_factor_l2}, {name: PowerFactorL3, var: power_factor_l3}, {name: Serial, var: serial}, {name: Temperature, var: temperature}, {name: ValueDate, var: value_date}, {name: Voltage, var: voltage}, {name: VoltageL1, var: voltage_l1}, {name: VoltageL2, var: voltage_l2}, {name: VoltageL3, var: voltage_l3}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    active_power: $active_power, counter_reading: $counter_reading, counter_reading_export: $counter_reading_export, counter_reading_export_t1: $counter_reading_export_t1, counter_reading_export_t2: $counter_reading_export_t2, counter_reading_t1: $counter_reading_t1, counter_reading_t2: $counter_reading_t2, current: $current, current_l1: $current_l1, current_l2: $current_l2, current_l3: $current_l3, device_energy_type: $device_energy_type, digital_input1: $digital_input1, id: $id, meter_sub_type: $meter_sub_type, name: $name, power_factor: $power_factor, power_factor_l1: $power_factor_l1, power_factor_l2: $power_factor_l2, power_factor_l3: $power_factor_l3, serial: $serial, temperature: $temperature, value_date: $value_date, voltage: $voltage, voltage_l1: $voltage_l1, voltage_l2: $voltage_l2, voltage_l3: $voltage_l3
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets a Device by it's ID
#
# GET /api/Devices/{id}
# Returns: record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
export def "get-api-devices-id" [
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
    path: "/api/Devices/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Updates the On/Off Switch on a device. For new implementations please use the "actions" command
#
# PUT /api/Devices/{id}
# Returns: record
# operationId: Devices_Put
export def "devices-put" [
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
  --switch-state: oneof<nothing, bool> # The new state of the switch (required)
  --switch-number: int # The number of the switch if there are multiple (1 for L1, 3 for L3) (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/api/Devices/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: switchState, var: switch_state, required: true}, {name: switchNumber, var: switch_number}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id, switch_state: $switch_state, switch_number: $switch_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Devices for an Energy Type
#
# GET /api/DevicesByEnergy
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: DevicesByEnergy_Get
export def "devices-by-energy-get" [
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
  --meter-energy-type: string@meter-energy-type-completer # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/DevicesByEnergy"
    query: [{name: meterEnergyType, var: meter_energy_type, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    meter_energy_type: $meter_energy_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Devices by it's Sub Type (e.g. E-Charging Station)
#
# GET /api/DevicesBySubType
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: DevicesBySubType_Get
export def "devices-by-sub-type-get" [
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
  --meter-sub-type: string@meter-sub-type-completer # required
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/DevicesBySubType"
    query: [{name: meterSubType, var: meter_sub_type, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    meter_sub_type: $meter_sub_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Force a device to send the data every second (if supported). This for about 30s. Don't use this call to force a device to send the data every second for a longer time.
#
# GET /api/FastSendDeviceValues/{id}
# operationId: FastSendDeviceValues_Get
export def "fast-send-device-values-get" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/FastSendDeviceValues/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the Values for a folder or a meter
#
# GET /api/Folder/{id}
# Returns: record<ElectricityCounterValue: float, ElectricityPower: float, GasCounterValue: float, GasFlowRate: float, HeatCounterValue: float, HeatPower: float, WaterCounterValue: float, WaterFlowRate: float>
# operationId: Folder_Get
export def "folder-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Folder/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the folder menu items (each item might contain child items)
#
# GET /api/FolderMenu
# Returns: record<BrowserTimeZoneName: string, BrowserUtcTime: string, Items: table<AutoExportSettings: record, Children: list, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>>
# operationId: FolderMenu_Get
export def "folder-menu-get" [
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
  --filter: string # (optional) Filter for the folders and meters: all: load everything assigned: load only folders and meters that are assigend to a folder unassigend: load only meters that are not assigend to a folder user: load only folder and all users assigned to this folders subuserlist: load all subusers as a list
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/FolderMenu"
    query: [{name: filter, var: filter}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates and updates the folder menu items
#
# POST /api/FolderMenu
# operationId: FolderMenu_Post
export def "folder-menu-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --browser-time-zone-name: string # The time zone name taken from the browser
  --browser-utc-time: string # The UTC time taken from the browser
  --items: list # item shape: {AutoExportSettings?: record, Children?: list, Description?: string, FolderType?: "Folder"|"Location"|"Factory"|"House"|"Office"|"Machine"|"VirtualMeter"|"ElecticityFolder"|"WaterFolder"|"HeatFolder"|"GasFolder"|"TemperatureFolder"|"Sun"|"Light"|"Ice"|"Sofa"|"Food"|"Coffee"|"Car"|"ChargingStation"|"Meter"|"User"|"Trash"|"GridPhotovoltaicPowerSystem", Icon?: string, Id?: string, MeterSerialNumber?: string, Name?: string, UserId?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/FolderMenu"
    body: {content_type: "application/json", kind: json, fields: [{name: BrowserTimeZoneName, var: browser_time_zone_name}, {name: BrowserUtcTime, var: browser_utc_time}, {name: Items, var: items}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    browser_time_zone_name: $browser_time_zone_name, browser_utc_time: $browser_utc_time, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A method returning HTTP 200 OK when queried. It is used by Kubernetes probes to determine whether the app is healthy.
#
# GET /api/Health
# Returns: record
# operationId: Health_Get
export def "health-get" [
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
    path: "/api/Health"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# M-BUS API: Adds data of a M-BUS Meter to the smart-me Cloud. Just send us the M-BUS Telegram (RSP_UD) and we will do the Rest.
#
# POST /api/MBus
# Returns: record
# operationId: MBus_Post
export def "m-bus-post" [
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
  --date: string # The Date of the M-BUS Telegram Readout (in UTC). If this is null the Server Time is used. (format: date-time)
  --telegram: string # The M-BUS Telegram as Hex string. Example: 68 1F 1F 68 08 02 72 78 56 34 12 24 40 01 07 55 00 00 00 03 13 15 31 00 DA 02 3B 13 01 8B 60 04 37 18 02 18 16
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/MBus"
    body: {content_type: "application/json", kind: json, fields: [{name: Date, var: date}, {name: Telegram, var: telegram}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    date: $date, telegram: $telegram
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sets the Name of a Meter or a Folder
#
# POST /api/MeterFolderInformation
# operationId: MeterFolderInformation_Post
export def "meter-folder-information-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the device or folder
  --name: string # Name of the Meter or Folder
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/MeterFolderInformation"
    body: {content_type: "application/json", kind: json, fields: [{name: Id, var: id}, {name: Name, var: name}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Beta: Gets the General Information for a Meter or a Folder
#
# GET /api/MeterFolderInformation/{id}
# Returns: record<CommunicationModuleFirmwareVersion: int, CommunicationModuleHardwareVersion: int, FirmwareVersion: int, HardwareVersion: int, InputInformations: table<Name: string, Number: int>, IsFolder: bool, Name: string, OutputInformations: table<ActionType: string, Name: string, Number: int, ObisCode: string>>
# operationId: MeterFolderInformation_Get
export def "meter-folder-information-get" [
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
    path: "/api/MeterFolderInformation/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the Values for a Meter at a given Date. The first Value found before the given Date is returned.
#
# GET /api/MeterValues/{id}
# Returns: record<CounterReading: float, CounterReadingExport: float, CounterReadingExportT1: float, CounterReadingExportT2: float, CounterReadingExportT3: float, CounterReadingExportT4: float, CounterReadingImport: float, CounterReadingImportT1: float, CounterReadingImportT2: float, CounterReadingImportT3: float, CounterReadingImportT4: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Date: string, Id: string, Serial: int>
# operationId: MeterValues_Get
export def "meter-values-get" [
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
  --date: string # required, format: date-time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/MeterValues/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: date, var: date, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all registrations for the Realtime API.
#
# GET /api/RegisterForRealtimeApi
# Returns: table<ApiUrl: string, BasicAuthPassword: string, BasicAuthUsername: string, Id: string, MeterId: string, RegistrationType: string, SerialNumber: string>
# operationId: RegisterForRealtimeApi_Get
export def "register-for-realtime-api-get" [
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
    path: "/api/RegisterForRealtimeApi"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates a new registration for the realtime API. The Realtime API sends you the data of the registred devices as soon as we have them on the cloud. More Information about the realtime API: https://www.smart-me.com/Description/api/realtimeapi.aspx
#
# POST /api/RegisterForRealtimeApi
# operationId: RegisterForRealtimeApi_Post
export def "register-for-realtime-api-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-url: string # The URL of your endpoint. To this endpoint all the values are send to.
  --basic-auth-password: string # The Password (basic auth) of your endpoint. Leave empty of none.
  --basic-auth-username: string # The Username (basic auth) of your endpoint. Leave empty of none.
  --id: string # The ID of the registration
  --meter-id: string # The ID of the Meter. Just used if the RegistrationType is "SingleMeterRegistration".
  --registration-type: string@registration-type-completer # The Type of this registration (per meter, per user, ...)
  --serial-number: string # The serial number of the Meter. Just used if the RegistrationType is "SingleMeterRegistration" and the MeterId is null. Example: 1 SME 01 63000000 or 6300000
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/RegisterForRealtimeApi"
    body: {content_type: "application/json", kind: json, fields: [{name: ApiUrl, var: api_url}, {name: BasicAuthPassword, var: basic_auth_password}, {name: BasicAuthUsername, var: basic_auth_username}, {name: Id, var: id}, {name: MeterId, var: meter_id}, {name: RegistrationType, var: registration_type}, {name: SerialNumber, var: serial_number}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    api_url: $api_url, basic_auth_password: $basic_auth_password, basic_auth_username: $basic_auth_username, id: $id, meter_id: $meter_id, registration_type: $registration_type, serial_number: $serial_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a realtime API registration.
#
# DELETE /api/RegisterForRealtimeApi/{id}
# operationId: RegisterForRealtimeApi_Delete
export def "register-for-realtime-api-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/RegisterForRealtimeApi/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sets the configuration of a smart-me device. The device needs to be online.
#
# POST /api/SmartMeDeviceConfiguration
# operationId: SmartMeDeviceConfiguration_Post
export def "smart-me-device-configuration-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device-encryption-key: string # The encryption key used to decrypt messages received from an external meter (used only for the smart-me modules)
  --device-pin-code: string # PIN code to enter on a external meter (e.g. for the FNN meters)
  --dns-update-state: string@dns-update-state-completer # Configuration of the dynamic DNS service. More information: http://wiki.smart-me.com/index.php/Dynamisches_DNS
  --enable-modbus-tcp: oneof<nothing, bool> # Enables or disables Modbus TCP (if the meter supports it).
  --id: string # The ID of the device
  --input-configuration: list # The configuration for the intput outputs — item shape: {Name?: string, Number?: int, OffText?: string, OnText?: string, Type?: "TariffInput"|"DigitalInput"}
  --output-configuration: list # The configuration for the external outputs — item shape: {DigitalOutputNoConnectionAction?: "Nothing"|"TurnOff"|"TurnOn"|"SetPwmValue", Name?: string, Number?: int, S0PulseValue?: "PulseValue1000Kwh"|"PulseValue10000Kwh", Type?: "ImpulseOutputActiveEnergy"|"ImpulseOutputActiveEnergyImport"|"ImpulseOutputActiveEnergyExport"|"ImpulseOutputReactiveEnergy"|"DigitalOutput"|"AnalogPwmSignalOutput"|"Disabled"}
  --show-reactive-energy: oneof<nothing, bool> # Shows the reactive energy values (if the meter supports it).
  --switch-configuration: list # The configuration for the phase switches — item shape: {CanSwitchOff?: bool, Number?: int}
  --upload-interval: string@upload-interval-completer # Number of seconds the device will upload the data. For smaller values maybe a professional license is needed.
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/SmartMeDeviceConfiguration"
    body: {content_type: "application/json", kind: json, fields: [{name: DeviceEncryptionKey, var: device_encryption_key}, {name: DevicePinCode, var: device_pin_code}, {name: DnsUpdateState, var: dns_update_state}, {name: EnableModbusTcp, var: enable_modbus_tcp}, {name: Id, var: id}, {name: InputConfiguration, var: input_configuration}, {name: OutputConfiguration, var: output_configuration}, {name: ShowReactiveEnergy, var: show_reactive_energy}, {name: SwitchConfiguration, var: switch_configuration}, {name: UploadInterval, var: upload_interval}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    device_encryption_key: $device_encryption_key, device_pin_code: $device_pin_code, dns_update_state: $dns_update_state, enable_modbus_tcp: $enable_modbus_tcp, id: $id, input_configuration: $input_configuration, output_configuration: $output_configuration, show_reactive_energy: $show_reactive_energy, switch_configuration: $switch_configuration, upload_interval: $upload_interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the configuration of a smart-me device.
#
# GET /api/SmartMeDeviceConfiguration/{id}
# Returns: record<DeviceEncryptionKey: string, DevicePinCode: string, DnsUpdateState: string, EnableModbusTcp: bool, Id: string, InputConfiguration: table<Name: string, Number: int, OffText: string, OnText: string, Type: string>, OutputConfiguration: table<DigitalOutputNoConnectionAction: string, Name: string, Number: int, S0PulseValue: string, Type: string>, ShowReactiveEnergy: bool, SwitchConfiguration: table<CanSwitchOff: bool, Number: int>, UploadInterval: string>
# operationId: SmartMeDeviceConfiguration_Get
export def "smart-me-device-configuration-get" [
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
    path: "/api/SmartMeDeviceConfiguration/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Creates or updates a subuser. To create a new user set no ID (empty)
#
# POST /api/SubUser
# operationId: SubUser_Post
export def "sub-user-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-end-date: string # The end date. until this date the user has access (format: date-time)
  --access-time-start-date: string # The start date. From this date the user has access (format: date-time)
  --email: string # The Email adress
  --id: string # The ID of the user
  --new-password: string # If set this is used a new password
  --permission-level: string@permission-level-completer # The permission level of the user
  --username: string # The username
]: any -> any {
  $in | http-request {
    method: post
    path: "/api/SubUser"
    body: {content_type: "application/json", kind: json, fields: [{name: AccessEndDate, var: access_end_date}, {name: AccessTimeStartDate, var: access_time_start_date}, {name: Email, var: email}, {name: Id, var: id}, {name: NewPassword, var: new_password}, {name: PermissionLevel, var: permission_level}, {name: Username, var: username}]}
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    access_end_date: $access_end_date, access_time_start_date: $access_time_start_date, email: $email, id: $id, new_password: $new_password, permission_level: $permission_level, username: $username
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subuser
#
# DELETE /api/SubUser/{id}
# operationId: SubUser_Delete
export def "sub-user-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/SubUser/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a sub user. The user must be assigend to the user that makes this call.
#
# GET /api/SubUser/{id}
# Returns: record<AccessEndDate: string, AccessTimeStartDate: string, Email: string, Id: string, NewPassword: string, PermissionLevel: string, Username: string>
# operationId: SubUser_Get
export def "sub-user-get" [
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
    path: "/api/SubUser/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Triggers user account deletion.
#
# DELETE /api/User
# Returns: record
# operationId: User_Delete
export def "user-delete" [
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
    method: delete
    path: "/api/User"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the informations for the user.
#
# GET /api/User
# Returns: record<ChildUsers: list<any>, Email: string, Id: int, IdAsString: string, IsAdmin: bool, Permissions: list<string>, Username: string>
# operationId: User_Get
export def "user-get" [
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
    path: "/api/User"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all (last) values of a device
#
# GET /api/Values/{id}
# Returns: record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>
# operationId: Values_Get
export def "values-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/Values/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all (last) values of a device The first Value found before the given Date is returned.
#
# GET /api/ValuesInPast/{id}
# Returns: record<Date: string, DeviceId: string, Values: table<Obis: string, Value: float>>
# operationId: ValuesInPast_Get
export def "values-in-past-get" [
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
  --accept: string@accept-completer-1 # Response content type
  --date: string # the date of the value (required, format: date-time)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/ValuesInPast/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: date, var: date, required: true}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id, date: $date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets multiple values of a device. This call needs a smart-me professional licence.
#
# GET /api/ValuesInPastMultiple/{id}
# Returns: table<Date: string, DeviceId: string, Values: list<record>>
# operationId: ValuesInPastMultiple_Get
export def "values-in-past-multiple-get" [
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
  --start-date: string # The date when the first value should start (required, format: date-time)
  --end-date: string # The date when the last value should start (required, format: date-time)
  --interval: int # The interval in minutes betwenn the values. 0 means as fast as possible. Only 1000 values can be get in one call. (required, format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/ValuesInPastMultiple/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}, {name: interval, var: interval, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id, start_date: $start_date, end_date: $end_date, interval: $interval
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Beta: Gets all active virtual meters
#
# GET /api/VirtualBillingMeterActive
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: VirtualBillingMeterActive_Get
export def "virtual-billing-meter-active-get" [
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
    path: "/api/VirtualBillingMeterActive"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Beta: Virtual Meter API: Activates a Meter and add the Consumption to a Virtual Meter assosiated with the User.
#
# POST /api/VirtualBillingMeterActive
# Returns: record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: VirtualBillingMeterActive_Post
export def "virtual-billing-meter-active-post" [
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
  --serial-number: string # The Serialnumber of the Meter to activate.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/VirtualBillingMeterActive"
    body: {content_type: "application/json", kind: json, fields: [{name: SerialNumber, var: serial_number}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    serial_number: $serial_number
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Beta: Virtual Meter API: Deactivates a Virtual Meter.
#
# POST /api/VirtualBillingMeterDeactivate
# Returns: record
# operationId: VirtualBillingMeterDeactivate_Post
export def "virtual-billing-meter-deactivate-post" [
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
  --id: string # The ID of the Virtual meter to deactivate
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/VirtualBillingMeterDeactivate"
    body: {content_type: "application/json", kind: json, fields: [{name: ID, var: id}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Beta: Gets all Meters available to activate as a Virtual Meter.
#
# GET /api/VirtualBillingMeters
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: VirtualBillingMeters_Get
export def "virtual-billing-meters-get" [
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
    path: "/api/VirtualBillingMeters"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Calculates a virtual meter from a formula. A meter is coded as ID("METERID")
#
# GET /api/VirtualMeterCalculateFormula
# Returns: record<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: VirtualMeterCalculateFormula_Get
export def "virtual-meter-calculate-formula-get" [
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
  --formula: string # required
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/VirtualMeterCalculateFormula"
    query: [{name: formula, var: formula, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    formula: $formula
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Virtual Tariffs of a user
#
# GET /api/VirtualTariff
# Returns: table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>
# operationId: VirtualTariff_Get
export def "virtual-tariff-get" [
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
    path: "/api/VirtualTariff"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all virtual tariffs of a folder
#
# GET /api/VirtualTariff/{id}
# Returns: record<Date: string, FolderId: string, Name: string, VirtualTariffs: table<Factor: float, Id: string, Name: string, Type: string, Unit: string, Value: float>>
export def "get-api-virtual-tariff-id" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/VirtualTariff/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the consumption of a folder with a virtuall tariffs.
#
# GET /api/VirtualTariffConsumption
# Returns: table<Consumption: float, Currency: string, Name: string, Price: float, TariffType: string>
# operationId: VirtualTariffConsumption_Get
export def "virtual-tariff-consumption-get" [
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
  --folder-id: string # The ID of the Folder (required)
  --start-date: string # The start date (UTC) (required, format: date-time)
  --end-date: string # The end date (UTC) (required, format: date-time)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/api/VirtualTariffConsumption"
    query: [{name: folderId, var: folder_id, required: true}, {name: startDate, var: start_date, required: true}, {name: endDate, var: end_date, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    folder_id: $folder_id, start_date: $start_date, end_date: $end_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all Virtual Tariffs for a property (folder)
#
# GET /api/VirtualTariffsForProperty/{id}
# Returns: table<Date: string, FolderId: string, Name: string, VirtualTariffs: list<record>>
# operationId: VirtualTariffsForProperty_Get
export def "virtual-tariffs-for-property-get" [
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
    path: "/api/VirtualTariffsForProperty/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the calculation status for a virtual tariff property
#
# GET /api/VirtualTariffsStatusForProperty/{id}
# Returns: string
# operationId: VirtualTariffsStatusForProperty_Get
export def "virtual-tariffs-status-for-property-get" [
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
]: nothing -> any {
  http-request {
    method: get
    path: "/api/VirtualTariffsStatusForProperty/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Assign a folder (source) or meter to another folder (target). Can be used to create a folder structure.
#
# POST /api/folder/assign
# operationId: FolderAssign_Post
export def "folder-assign-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the meter or folder that should be assign (required)
  --target: string # The ID of the meter or folder that should be the parent (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/folder/assign"
    query: [{name: source, var: source, required: true}, {name: target, var: target, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a folder
#
# DELETE /api/folder/settings/{id}
# operationId: FolderSettings_Delete
export def "folder-settings-delete" [
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
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/folder/settings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the settings of a folder or meter
#
# GET /api/folder/settings/{id}
# Returns: record<Description: string, Enable: bool, FolderType: string, Name: string, ParentFolderId: string, SerialNumber: int, UseableForVirtualBillingMeters: bool, ValueCorrection: float, ValueCorrectionParentFolder: float, VisualizationName: string>
# operationId: FolderSettings_Get
export def "folder-settings-get" [
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
    path: "/api/folder/settings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Add or edit a folder or a meter. To add a new folder use and empty ID
#
# POST /api/folder/settings/{id}
# Returns: record<AutoExportSettings: record<ExportFormat: string, ExportInterval: string, MeterPointId: string, UploadType: string>, Children: list<any>, Description: string, FolderType: string, Icon: string, Id: string, MeterSerialNumber: string, Name: string, UserId: string>
# operationId: FolderSettings_Post
export def "folder-settings-post" [
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
  --description: string # The Description of the folder or meter
  --enable: oneof<nothing, bool> # Flag if the meter is enabled (folder not supported yet)
  --folder-type: string@folder-type-completer # The Type of the folder
  --name: string # The Name of the folder or meter
  --parent-folder-id: string # The parent folder ID of this item
  --serial-number: int # The serial number (meter only) (format: int64)
  --useable-for-virtual-billing-meters: oneof<nothing, bool> # Flag if the meter is usable for virtual billing meters (e.g. washroom)
  --value-correction: float # The value correction on this meter (format: double)
  --value-correction-parent-folder: float # The value correction on all parent folders. but not on the meter itself (format: double)
  --visualization-name: string # The name of the visualization of the folder
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/api/folder/settings/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Description, var: description}, {name: Enable, var: enable}, {name: FolderType, var: folder_type}, {name: Name, var: name}, {name: ParentFolderId, var: parent_folder_id}, {name: SerialNumber, var: serial_number}, {name: UseableForVirtualBillingMeters, var: useable_for_virtual_billing_meters}, {name: ValueCorrection, var: value_correction}, {name: ValueCorrectionParentFolder, var: value_correction_parent_folder}, {name: VisualizationName, var: visualization_name}]}
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id, description: $description, enable: $enable, folder_type: $folder_type, name: $name, parent_folder_id: $parent_folder_id, serial_number: $serial_number, useable_for_virtual_billing_meters: $useable_for_virtual_billing_meters, value_correction: $value_correction, value_correction_parent_folder: $value_correction_parent_folder, visualization_name: $visualization_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Deletes a user to folder assignement
#
# DELETE /api/folder/user/assign
# operationId: UserToFolderAssign_Delete
export def "user-to-folder-assign-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the user that should be de-assign (required)
  --target: string # The ID of the folder (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/api/folder/user/assign"
    query: [{name: source, var: source, required: true}, {name: target, var: target, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    source: $source, target: $target
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Assign a user to a folder
#
# POST /api/folder/user/assign
# operationId: UserToFolderAssign_Post
export def "user-to-folder-assign-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source: string # The ID of the user that should be assign (required)
  --target: string # The ID of the folder that should be the parent (required)
  --old-folder: string # The ID of the old folder (in case of a drag and drop to a new folder) (required)
]: nothing -> any {
  http-request {
    method: post
    path: "/api/folder/user/assign"
    query: [{name: source, var: source, required: true}, {name: target, var: target, required: true}, {name: oldFolder, var: old_folder, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: basic
  } {
    source: $source, target: $target, old_folder: $old_folder
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /api/oauth/authorize
#
# Returns: record
# operationId: OAuth_Authorize
export def "o-auth-authorize" [
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
  --client-id: string # required
  --redirect-uri: string # required
  --state: string # required
  --scope: string
  --client-secret: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/oauth/authorize"
    query: [{name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: state, var: state, required: true}, {name: scope, var: scope}, {name: client_secret, var: client_secret}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    client_id: $client_id, redirect_uri: $redirect_uri, state: $state, scope: $scope, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# POST /api/oauth/authorize
#
# Returns: record
export def "post-api-oauth-authorize" [
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
  --client-id: string # required
  --redirect-uri: string # required
  --state: string # required
  --scope: string
  --client-secret: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/oauth/authorize"
    query: [{name: client_id, var: client_id, required: true}, {name: redirect_uri, var: redirect_uri, required: true}, {name: state, var: state, required: true}, {name: scope, var: scope}, {name: client_secret, var: client_secret}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    client_id: $client_id, redirect_uri: $redirect_uri, state: $state, scope: $scope, client_secret: $client_secret
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets all pico charging stations for this user
#
# GET /api/pico
# Returns: table<ActivePower: float, ActivePowerL1: float, ActivePowerL2: float, ActivePowerL3: float, ActivePowerUnit: string, ActiveTariff: int, AdditionalMeterSerialNumber: string, AnalogOutput1: int, AnalogOutput2: int, ChargingStationState: string, CounterReading: float, CounterReadingExport: float, CounterReadingImport: float, CounterReadingT1: float, CounterReadingT2: float, CounterReadingT3: float, CounterReadingT4: float, CounterReadingUnit: string, Current: float, CurrentL1: float, CurrentL2: float, CurrentL3: float, DeviceEnergyType: string, DigitalInput1: bool, DigitalInput2: bool, DigitalOutput1: bool, DigitalOutput2: bool, FamilyType: string, FlowRate: float, Id: string, MeterSubType: string, Name: string, PowerFactor: float, PowerFactorL1: float, PowerFactorL2: float, PowerFactorL3: float, Serial: int, SwitchOn: bool, SwitchPhaseL1On: bool, SwitchPhaseL2On: bool, SwitchPhaseL3On: bool, Temperature: float, ValueDate: string, Voltage: float, VoltageL1: float, VoltageL2: float, VoltageL3: float>
# operationId: Pico_Get
export def "pico-get" [
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
    path: "/api/pico"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the active charging data of a pico station
#
# GET /api/pico/charging/{id}
# Returns: record<ActiveChargingEnergy: float, ActiveChargingPower: float, ConnectionMode: string, Duration: int, LastWarningOrError: string, LastWarningOrErrorMessage: string, LastWarningOrErrorTime: string, LoadSheddingState: string, LoadmanagementGroupName: string, MaxAllowedChargingCurrent: int, MaxDynamicCurrent: int, MaxLoadmanagementGroupCurrent: int, MaxStationCurrent: int, MinStationCurrent: int, State: string, ValueDate: string>
# operationId: PicoCharging_Get
export def "pico-charging-get" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/api/pico/charging/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "text/json"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Gets the last charging history for a pico station
#
# GET /api/pico/history/{id}
# Returns: table<Duration: int, EnergyUsed: float, StartTime: string>
# operationId: PicoChargingHistory_Get
export def "pico-charging-history-get" [
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
    path: "/api/pico/history/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET: api/pico/loadmanagementgroup Returns all available load management groups
#
# GET /api/pico/loadmanagementgroup
# Returns: table<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>
export def "get-api-pico-loadmanagementgroup" [
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
    path: "/api/pico/loadmanagementgroup"
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Sets the dynamic current of a load management group or a single station.
#
# POST /api/pico/loadmanagementgroup/current/{serial}
# Returns: record
# operationId: PicoLoadmanagementSetDynamicCurrent_Post
export def "pico-loadmanagement-set-dynamic-current-post" [
  serial: int
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
  --current: int # The dynamic current of the group (in mA) (required, format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/api/pico/loadmanagementgroup/current/{serial}"
    path_params: [{name: serial, var: serial}]
    query: [{name: current, var: current, required: true}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    serial: $serial, current: $current
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET: api/pico/loadmanagementgroup Returns a pico load management group by it's id
#
# GET /api/pico/loadmanagementgroup/{id}
# Returns: record<Id: string, MaxCurrent: float, Name: string, NumberOfStations: int>
# operationId: PicoLoadmanagementGroup_Get
export def "pico-loadmanagement-group-get" [
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
    path: "/api/pico/loadmanagementgroup/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# GET: api/pico/settings Returns the settings of a pico charging station.
#
# GET /api/pico/settings/{id}
# Returns: record<AuthenticationType: string, CarIdDetection: bool, DisplayBrightness: string, DnsName: string, FixCableLockEnable: bool, IdleImageUrl: string, InternalIp: string, LoadmanagementGroupId: string, MaxCurrent: int, MinCurrent: int, ModbusTcp: bool, Name: string, SerialNumber: string>
# operationId: PicoSettings_Get
export def "pico-settings-get" [
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
    path: "/api/pico/settings/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Try to fix lock the cable of a pico. The pico must be online and a cable (without car) needs to be connected. Otherwise this will fail.
#
# POST /api/pico/tryenablecablelock/{id}
# Returns: record
# operationId: PicoEnableFixCableLock_Post
export def "pico-enable-fix-cable-lock-post" [
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
    method: post
    path: "/api/pico/tryenablecablelock/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json", "application/xml", "text/json", "text/xml"]
    ok: [200]
    auth: basic
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
