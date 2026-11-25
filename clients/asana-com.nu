# Auto-generated client for Asana v1.0
# Source: https://api.apis.guru/v2/specs/asana.com/1.0/openapi.json
# Auth: --token flag or $env.ASANA_TOKEN

const CLIENT = {
  base_url: "https://app.asana.com/api/1.0"
  token_env_var: "ASANA_TOKEN"
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

def base-url-completer [] { ["https://app.asana.com/api/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-subtype-completer [] { ["asana" "box" "dropbox" "external" "gdrive" "onedrive" "vimeo"] }
def resource-type-completer [] { ["portfolio" "project" "project_template" "tag" "task" "user"] }
def actor-type-completer [] { ["anonymous" "asana" "asana_support" "external_administrator" "user"] }
def resource-subtype-completer-1 [] { ["default_task" "milestone"] }
def sort-by-completer [] { ["completed_at" "created_at" "due_date" "likes" "modified_at"] }
def resource-type-completer-1 [] { ["custom_field" "portfolio" "project" "project_template" "tag" "task" "user"] }
def type-completer [] { ["custom_field" "portfolio" "project" "tag" "task" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-attachments-for-object: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    create-attachment-for-object: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permanent_url: string, size: int, view_url: string>>"
    delete-attachment: "record<data: record>"
    get-attachment: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permanent_url: string, size: int, view_url: string>>"
    create-batch-request: "record<data: table<body: record, headers: record, status_code: int>>"
    create-custom-field: "record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>"
    delete-custom-field: "record<data: record>"
    get-custom-field: "record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>"
    update-custom-field: "record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>"
    create-enum-option-for-custom-field: "record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>"
    insert-enum-option-for-custom-field: "record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>"
    update-enum-option: "record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>"
    get-events: "record<data: table<action: string, change: record, created_at: string, parent: record, resource: record, type: string, user: record>, has_more: bool, sync: string>"
    get-goal-relationships: "record<data: table<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record>>"
    get-goal-relationship: "record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>"
    update-goal-relationship: "record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>"
    get-goals: "record<data: table<gid: string, resource_type: string, name: string, owner: record>>"
    create-goal: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    delete-goal: "record<data: record>"
    get-goal: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    update-goal: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    add-followers: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    add-supporting-relationship: "record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>"
    get-parent-goals-for-goal: "record<data: table<gid: string, resource_type: string, name: string, owner: record>>"
    remove-followers: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    remove-supporting-relationship: "record<data: record>"
    create-goal-metric: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    update-goal-metric: "record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-job: "record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>"
    create-organization-export: "record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>>"
    get-organization-export: "record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>>"
    get-portfolio-memberships: "record<data: table<gid: string, resource_type: string, portfolio: record, user: record>>"
    get-portfolio-membership: "record<data: record<gid: string, resource_type: string, portfolio: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>"
    get-portfolios: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-portfolio: "record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    delete-portfolio: "record<data: record>"
    get-portfolio: "record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    update-portfolio: "record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    add-custom-field-setting-for-portfolio: "record<data: record<gid: string, resource_type: string, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>>>"
    add-item-for-portfolio: "record<data: record>"
    add-members-for-portfolio: "record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-custom-field-settings-for-portfolio: "record<data: table<gid: string, resource_type: string, custom_field: record, is_important: bool, parent: record, project: record>>"
    get-items-for-portfolio: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-portfolio-memberships-for-portfolio: "record<data: table<gid: string, resource_type: string, portfolio: record, user: record>>"
    remove-custom-field-setting-for-portfolio: "record<data: record>"
    remove-item-for-portfolio: "record<data: record>"
    remove-members-for-portfolio: "record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    delete-project-brief: "record<data: record>"
    get-project-brief: "record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>"
    update-project-brief: "record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>"
    get-project-membership: "record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>, write_access: string>>"
    delete-project-status: "record<data: record>"
    get-project-status: "record<data: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>>"
    get-project-templates: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-project-template: "record<data: record<gid: string, resource_type: string, name: string, color: string, description: string, html_description: string, owner: record<gid: string, resource_type: string, name: string>, public: bool, requested_dates: list<record>, team: record<gid: string, resource_type: string, name: string>>>"
    instantiate-project: "record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>"
    get-projects: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    delete-project: "record<data: record>"
    get-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    update-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    add-custom-field-setting-for-project: "record<data: record<gid: string, resource_type: string, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>>>"
    add-followers-for-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    add-members-for-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    get-custom-field-settings-for-project: "record<data: table<gid: string, resource_type: string, custom_field: record, is_important: bool, parent: record, project: record>>"
    duplicate-project: "record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>"
    create-project-brief: "record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>"
    get-project-memberships-for-project: "record<data: table<gid: string, resource_type: string, user: record>>"
    get-project-statuses-for-project: "record<data: table<gid: string, resource_type: string, title: string>>"
    create-project-status-for-project: "record<data: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>>"
    remove-custom-field-setting-for-project: "record<data: record>"
    remove-followers-for-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    remove-members-for-project: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    project-save-as-template: "record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>"
    get-sections-for-project: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-section-for-project: "record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>"
    insert-section-for-project: "record<data: record>"
    get-task-counts-for-project: "record<data: record<num_completed_milestones: int, num_completed_tasks: int, num_incomplete_milestones: int, num_incomplete_tasks: int, num_milestones: int, num_tasks: int>>"
    get-tasks-for-project: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    delete-section: "record<data: record>"
    get-section: "record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>"
    update-section: "record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>"
    add-task-for-section: "record<data: record>"
    get-tasks-for-section: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    get-statuses-for-object: "record<data: table<gid: string, resource_type: string, resource_subtype: string, title: string>>"
    create-status-for-object: "record<data: record<gid: string, resource_type: string, resource_subtype: string, title: string, html_text: string, status_type: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>>"
    delete-status: "record<data: record>"
    get-status: "record<data: record<gid: string, resource_type: string, resource_subtype: string, title: string, html_text: string, status_type: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>>"
    delete-story: "record<data: record>"
    get-story: "record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>"
    update-story: "record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>"
    get-tags: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-tag: "record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    delete-tag: "record<data: record>"
    get-tag: "record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    update-tag: "record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-tasks-for-tag: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    get-tasks: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    create-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    delete-task: "record<data: record>"
    get-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    update-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    add-dependencies-for-task: "record<data: record>"
    add-dependents-for-task: "record<data: record>"
    add-followers-for-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    add-project-for-task: "record<data: record>"
    add-tag-for-task: "record<data: record>"
    get-dependencies-for-task: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    get-dependents-for-task: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    duplicate-task: "record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>"
    get-projects-for-task: "record<data: table<gid: string, resource_type: string, name: string>>"
    remove-dependencies-for-task: "record<data: record>"
    remove-dependents-for-task: "record<data: record>"
    remove-follower-for-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    remove-project-for-task: "record<data: record>"
    remove-tag-for-task: "record<data: record>"
    set-parent-for-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-stories-for-task: "record<data: table<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>>"
    create-story-for-task: "record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>"
    get-subtasks-for-task: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    create-subtask-for-task: "record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-tags-for-task: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-team-memberships: "record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>"
    get-team-membership: "record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>"
    create-team: "record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>"
    update-team: "record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>"
    get-team: "record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>"
    add-user-for-team: "record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>"
    get-project-templates-for-team: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-projects-for-team: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-project-for-team: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    remove-user-for-team: "record<data: record>"
    get-team-memberships-for-team: "record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>"
    get-users-for-team: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-time-periods: "record<data: table<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>>"
    get-time-period: "record<data: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string, parent: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>>>"
    get-user-task-list: "record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-tasks-for-user-task-list: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    get-users: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-user: "record<data: record<gid: string, resource_type: string, name: string, email: string, photo: record<image_1024x1024: string, image_128x128: string, image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string>, workspaces: list<record>>>"
    get-favorites-for-user: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-team-memberships-for-user: "record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>"
    get-teams-for-user: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-user-task-list-for-user: "record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>>"
    get-workspace-memberships-for-user: "record<data: table<gid: string, resource_type: string, user: record, workspace: record>>"
    get-webhooks: "record<data: table<gid: string, resource_type: string, active: bool, resource: record, target: string, created_at: string, filters: list, last_failure_at: string, last_failure_content: string, last_success_at: string>>"
    create-webhook: "record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>"
    delete-webhook: "record<data: record>"
    get-webhook: "record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>"
    update-webhook: "record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>"
    get-workspace-membership: "record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, is_active: bool, is_admin: bool, is_guest: bool, user_task_list: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>, vacation_dates: record<end_on: string, start_on: string>>>"
    get-workspaces: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-workspace: "record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>>"
    update-workspace: "record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>>"
    add-user-for-workspace: "record<data: record<gid: string, resource_type: string, name: string, email: string, photo: record<image_1024x1024: string, image_128x128: string, image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string>>>"
    get-audit-log-events: "record<data: table<actor: record, context: record, created_at: string, details: record, event_category: string, event_type: string, gid: string, resource: record>>"
    get-custom-fields-for-workspace: "record<data: table<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>>"
    get-projects-for-workspace: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-project-for-workspace: "record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>"
    remove-user-for-workspace: "record<data: record>"
    get-tags-for-workspace: "record<data: table<gid: string, resource_type: string, name: string>>"
    create-tag-for-workspace: "record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>"
    search-tasks-for-workspace: "record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>"
    get-teams-for-workspace: "record<data: table<gid: string, resource_type: string, name: string>>"
    typeahead-for-workspace: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-users-for-workspace: "record<data: table<gid: string, resource_type: string, name: string>>"
    get-workspace-memberships-for-workspace: "record<data: table<gid: string, resource_type: string, user: record, workspace: record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-attachments-for-object" "create-attachment-for-object" "delete-attachment" "get-attachment" "create-batch-request" "create-custom-field" "delete-custom-field" "get-custom-field" "update-custom-field" "create-enum-option-for-custom-field" "insert-enum-option-for-custom-field" "update-enum-option" "get-events" "get-goal-relationships" "get-goal-relationship" "update-goal-relationship" "get-goals" "create-goal" "delete-goal" "get-goal" "update-goal" "add-followers" "add-supporting-relationship" "get-parent-goals-for-goal" "remove-followers" "remove-supporting-relationship" "create-goal-metric" "update-goal-metric" "get-job" "create-organization-export" "get-organization-export" "get-portfolio-memberships" "get-portfolio-membership" "get-portfolios" "create-portfolio" "delete-portfolio" "get-portfolio" "update-portfolio" "add-custom-field-setting-for-portfolio" "add-item-for-portfolio" "add-members-for-portfolio" "get-custom-field-settings-for-portfolio" "get-items-for-portfolio" "get-portfolio-memberships-for-portfolio" "remove-custom-field-setting-for-portfolio" "remove-item-for-portfolio" "remove-members-for-portfolio" "delete-project-brief" "get-project-brief" "update-project-brief" "get-project-membership" "delete-project-status" "get-project-status" "get-project-templates" "get-project-template" "instantiate-project" "get-projects" "create-project" "delete-project" "get-project" "update-project" "add-custom-field-setting-for-project" "add-followers-for-project" "add-members-for-project" "get-custom-field-settings-for-project" "duplicate-project" "create-project-brief" "get-project-memberships-for-project" "get-project-statuses-for-project" "create-project-status-for-project" "remove-custom-field-setting-for-project" "remove-followers-for-project" "remove-members-for-project" "project-save-as-template" "get-sections-for-project" "create-section-for-project" "insert-section-for-project" "get-task-counts-for-project" "get-tasks-for-project" "delete-section" "get-section" "update-section" "add-task-for-section" "get-tasks-for-section" "get-statuses-for-object" "create-status-for-object" "delete-status" "get-status" "delete-story" "get-story" "update-story" "get-tags" "create-tag" "delete-tag" "get-tag" "update-tag" "get-tasks-for-tag" "get-tasks" "create-task" "delete-task" "get-task" "update-task" "add-dependencies-for-task" "add-dependents-for-task" "add-followers-for-task" "add-project-for-task" "add-tag-for-task" "get-dependencies-for-task" "get-dependents-for-task" "duplicate-task" "get-projects-for-task" "remove-dependencies-for-task" "remove-dependents-for-task" "remove-follower-for-task" "remove-project-for-task" "remove-tag-for-task" "set-parent-for-task" "get-stories-for-task" "create-story-for-task" "get-subtasks-for-task" "create-subtask-for-task" "get-tags-for-task" "get-team-memberships" "get-team-membership" "create-team" "update-team" "get-team" "add-user-for-team" "get-project-templates-for-team" "get-projects-for-team" "create-project-for-team" "remove-user-for-team" "get-team-memberships-for-team" "get-users-for-team" "get-time-periods" "get-time-period" "get-user-task-list" "get-tasks-for-user-task-list" "get-users" "get-user" "get-favorites-for-user" "get-team-memberships-for-user" "get-teams-for-user" "get-user-task-list-for-user" "get-workspace-memberships-for-user" "get-webhooks" "create-webhook" "delete-webhook" "get-webhook" "update-webhook" "get-workspace-membership" "get-workspaces" "get-workspace" "update-workspace" "add-user-for-workspace" "get-audit-log-events" "get-custom-fields-for-workspace" "get-projects-for-workspace" "create-project-for-workspace" "remove-user-for-workspace" "get-tags-for-workspace" "create-tag-for-workspace" "search-tasks-for-workspace" "get-teams-for-workspace" "typeahead-for-workspace" "get-users-for-workspace" "get-workspace-memberships-for-workspace" "commands"] | sort) } | get name | first)
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

# Get attachments from an object
#
# GET /attachments
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getAttachmentsForObject
export def "get-attachments-for-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a `project`, `project_brief`, or `task`. (required, e.g. 159874)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attachments"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: parent, var: parent, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, parent: $parent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload an attachment
#
# POST /attachments
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permanent_url: string, size: int, view_url: string>>
# operationId: createAttachmentForObject
export def "create-attachment-for-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --connect-to-app: oneof<nothing, bool> # *Optional*. Only relevant for external attachments with a parent task. A boolean indicating whether the current app should be connected with the attachment for the purposes of showing an app components widget. Requires the app to have been added to a project the parent task is in.
  --file: string # Required for `asana` attachments. (format: binary)
  --name: string # The name of the external resource being attached. Required for attachments of type `external`.
  --parent: string # Required identifier of the parent task, project, or project_brief, as a string.
  --resource-subtype: string@resource-subtype-completer # The type of the attachment. Must be one of the given values. If not specified, a file attachment of type `asana` will be assumed. Note that if the value of `resource_subtype` is `external`, a `parent`, `name`, and `url` must also be provided. (e.g. external)
  --url: string # The URL of the external resource being attached. Required for attachments of type `external`.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/attachments"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: connect_to_app, var: connect_to_app}, {name: file, var: file}, {name: name, var: name}, {name: parent, var: parent}, {name: resource_subtype, var: resource_subtype}, {name: url, var: url}], files: [file]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, connect_to_app: $connect_to_app, file: $file, name: $name, parent: $parent, resource_subtype: $resource_subtype, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an attachment
#
# DELETE /attachments/{attachment_gid}
# Returns: record<data: record>
# operationId: deleteAttachment
export def "delete-attachment" [
  attachment_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/attachments/{attachment_gid}"
    path_params: [{name: attachment_gid, var: attachment_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_gid: $attachment_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an attachment
#
# GET /attachments/{attachment_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, connected_to_app: bool, created_at: string, download_url: string, host: string, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permanent_url: string, size: int, view_url: string>>
# operationId: getAttachment
export def "get-attachment" [
  attachment_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/attachments/{attachment_gid}"
    path_params: [{name: attachment_gid, var: attachment_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    attachment_gid: $attachment_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit parallel requests
#
# POST /batch
# Returns: record<data: table<body: record, headers: record, status_code: int>>
# operationId: createBatchRequest
export def "create-batch-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A request object for use in a batch request. — shape: {actions?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/batch"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a custom field
#
# POST /custom_fields
# Returns: record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>
# operationId: createCustomField
export def "create-custom-field" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {date_value?: record, enabled?: bool, enum_options?: list, enum_value?: record, multi_enum_values?: list, name?: string, number_value?: float, resource_subtype?: "text"|"enum"|"multi_enum"|"number"|"date"|"people", text_value?: string, currency_code?: string, custom_label?: string, custom_label_position?: "prefix"|"suffix", description?: string, format?: "currency"|"identifier"|"percentage"|"custom"|"none", has_notifications_enabled?: bool, precision?: int, people_value?: list<string>, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_fields"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a custom field
#
# DELETE /custom_fields/{custom_field_gid}
# Returns: record<data: record>
# operationId: deleteCustomField
export def "delete-custom-field" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/custom_fields/{custom_field_gid}"
    path_params: [{name: custom_field_gid, var: custom_field_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_gid: $custom_field_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a custom field
#
# GET /custom_fields/{custom_field_gid}
# Returns: record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>
# operationId: getCustomField
export def "get-custom-field" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/custom_fields/{custom_field_gid}"
    path_params: [{name: custom_field_gid, var: custom_field_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_gid: $custom_field_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a custom field
#
# PUT /custom_fields/{custom_field_gid}
# Returns: record<data: record<gid: string, resource_type: string, date_value: record<date: string, date_time: string>, display_value: string, enabled: bool, enum_options: list<record>, enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, multi_enum_values: list<record>, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record<gid: string, resource_type: string, name: string>, people_value: list<record>>>
# operationId: updateCustomField
export def "update-custom-field" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {date_value?: record, enabled?: bool, enum_options?: list, enum_value?: record, multi_enum_values?: list, name?: string, number_value?: float, resource_subtype?: "text"|"enum"|"multi_enum"|"number"|"date"|"people", text_value?: string, currency_code?: string, custom_label?: string, custom_label_position?: "prefix"|"suffix", description?: string, format?: "currency"|"identifier"|"percentage"|"custom"|"none", has_notifications_enabled?: bool, precision?: int, people_value?: list<string>, ... (1 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/custom_fields/{custom_field_gid}"
    path_params: [{name: custom_field_gid, var: custom_field_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_gid: $custom_field_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an enum option
#
# POST /custom_fields/{custom_field_gid}/enum_options
# Returns: record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>
# operationId: createEnumOptionForCustomField
export def "create-enum-option-for-custom-field" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {color?: string, enabled?: bool, name?: string, insert_after?: string, insert_before?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_fields/{custom_field_gid}/enum_options"
    path_params: [{name: custom_field_gid, var: custom_field_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    custom_field_gid: $custom_field_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reorder a custom field's enum
#
# POST /custom_fields/{custom_field_gid}/enum_options/insert
# Returns: record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>
# operationId: insertEnumOptionForCustomField
export def "insert-enum-option-for-custom-field" [
  custom_field_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {after_enum_option?: string, before_enum_option?: string, enum_option: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/custom_fields/{custom_field_gid}/enum_options/insert"
    path_params: [{name: custom_field_gid, var: custom_field_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    custom_field_gid: $custom_field_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an enum option
#
# PUT /enum_options/{enum_option_gid}
# Returns: record<data: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>>
# operationId: updateEnumOption
export def "update-enum-option" [
  enum_option_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {color?: string, enabled?: bool, name?: string, insert_after?: string, insert_before?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/enum_options/{enum_option_gid}"
    path_params: [{name: enum_option_gid, var: enum_option_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    enum_option_gid: $enum_option_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events on a resource
#
# GET /events
# Returns: record<data: table<action: string, change: record, created_at: string, parent: record, resource: record, type: string, user: record>, has_more: bool, sync: string>
# operationId: getEvents
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # A resource ID to subscribe to. The resource can be a task or project. (required, e.g. 12345)
  --sync: string # A sync token received from the last request, or none on first sync. Events will be returned from the point in time that the sync token was generated. *Note: On your first request, omit the sync token. The response will be the same as for an expired sync token, and will include a new valid sync token.If the sync token is too old (which may happen from time to time) the API will return a `412 Precondition Failed` error, and include a fresh sync token in the response.* (e.g. de4774f6915eae04714ca93bb2f5ee81)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: resource, var: resource, required: true}, {name: sync, var: sync}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource: $resource, sync: $sync, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get goal relationships
#
# GET /goal_relationships
# Returns: record<data: table<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record>>
# operationId: getGoalRelationships
export def "get-goal-relationships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --supported-goal: string # Globally unique identifier for the supported goal in the goal relationship. (required, e.g. 12345)
  --resource-subtype: string # If provided, filter to goal relationships with a given resource_subtype. (e.g. subgoal)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/goal_relationships"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: supported_goal, var: supported_goal, required: true}, {name: resource_subtype, var: resource_subtype}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, supported_goal: $supported_goal, resource_subtype: $resource_subtype
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a goal relationship
#
# GET /goal_relationships/{goal_relationship_gid}
# Returns: record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>
# operationId: getGoalRelationship
export def "get-goal-relationship" [
  goal_relationship_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/goal_relationships/{goal_relationship_gid}"
    path_params: [{name: goal_relationship_gid, var: goal_relationship_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_relationship_gid: $goal_relationship_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a goal relationship
#
# PUT /goal_relationships/{goal_relationship_gid}
# Returns: record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>
# operationId: updateGoalRelationship
export def "update-goal-relationship" [
  goal_relationship_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {contribution_weight?: float, supporting_resource?: record, supported_goal?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/goal_relationships/{goal_relationship_gid}"
    path_params: [{name: goal_relationship_gid, var: goal_relationship_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_relationship_gid: $goal_relationship_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get goals
#
# GET /goals
# Returns: record<data: table<gid: string, resource_type: string, name: string, owner: record>>
# operationId: getGoals
export def "get-goals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --portfolio: string # Globally unique identifier for supporting portfolio. (e.g. 159874)
  --project: string # Globally unique identifier for supporting project. (e.g. 512241)
  --is-workspace-level: oneof<nothing, bool> # Filter to goals with is_workspace_level set to query value. Must be used with the workspace parameter. (e.g. false)
  --team: string # Globally unique identifier for the team. (e.g. 31326)
  --workspace: string # Globally unique identifier for the workspace. (e.g. 31326)
  --time-periods: list<string> # Globally unique identifiers for the time periods. (e.g. 221693,506165)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/goals"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: portfolio, var: portfolio}, {name: project, var: project}, {name: is_workspace_level, var: is_workspace_level}, {name: team, var: team}, {name: workspace, var: workspace}, {name: time_periods, var: time_periods, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, portfolio: $portfolio, project: $project, is_workspace_level: $is_workspace_level, team: $team, workspace: $workspace, time_periods: $time_periods
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a goal
#
# POST /goals
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createGoal
export def "create-goal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {due_on?: string, html_notes?: string, is_workspace_level?: bool, liked?: bool, name?: string, notes?: string, start_on?: string, status?: string, followers?: list<string>, owner?: string, team?: string, time_period?: string, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a goal
#
# DELETE /goals/{goal_gid}
# Returns: record<data: record>
# operationId: deleteGoal
export def "delete-goal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/goals/{goal_gid}"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a goal
#
# GET /goals/{goal_gid}
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getGoal
export def "get-goal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/goals/{goal_gid}"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a goal
#
# PUT /goals/{goal_gid}
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: updateGoal
export def "update-goal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {due_on?: string, html_notes?: string, is_workspace_level?: bool, liked?: bool, name?: string, notes?: string, start_on?: string, status?: string, followers?: list<string>, owner?: string, team?: string, time_period?: string, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/goals/{goal_gid}"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a collaborator to a goal
#
# POST /goals/{goal_gid}/addFollowers
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: addFollowers
export def "add-followers" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/addFollowers"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a supporting goal relationship
#
# POST /goals/{goal_gid}/addSupportingRelationship
# Returns: record<data: record<gid: string, resource_type: string, contribution_weight: float, resource_subtype: string, supporting_resource: record<gid: string, resource_type: string, name: string>, supported_goal: record<gid: string, resource_type: string, name: string, owner: record>>>
# operationId: addSupportingRelationship
export def "add-supporting-relationship" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {contribution_weight?: float, insert_after?: string, insert_before?: string, supporting_resource: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/addSupportingRelationship"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get parent goals from a goal
#
# GET /goals/{goal_gid}/parentGoals
# Returns: record<data: table<gid: string, resource_type: string, name: string, owner: record>>
# operationId: getParentGoalsForGoal
export def "get-parent-goals-for-goal" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/goals/{goal_gid}/parentGoals"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a collaborator from a goal
#
# POST /goals/{goal_gid}/removeFollowers
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: removeFollowers
export def "remove-followers" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/removeFollowers"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a supporting goal relationship
#
# POST /goals/{goal_gid}/removeSupportingRelationship
# Returns: record<data: record>
# operationId: removeSupportingRelationship
export def "remove-supporting-relationship" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {supporting_resource: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/removeSupportingRelationship"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a goal metric
#
# POST /goals/{goal_gid}/setMetric
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createGoalMetric
export def "create-goal-metric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {currency_code?: string, current_number_value?: float, initial_number_value?: float, precision?: int, progress_source?: "manual"|"subgoal_progress"|"project_task_completion"|"project_milestone_completion"|"external", target_number_value?: float, unit?: "none"|"currency"|"percentage"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/setMetric"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a goal metric
#
# POST /goals/{goal_gid}/setMetricCurrentValue
# Returns: record<data: record<gid: string, resource_type: string, due_on: string, html_notes: string, is_workspace_level: bool, liked: bool, name: string, notes: string, start_on: string, status: string, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, followers: list<record>, likes: list<record>, metric: record<gid: string, resource_type: string, currency_code: string, current_display_value: string, current_number_value: float, initial_number_value: float, precision: int, progress_source: string, resource_subtype: string, target_number_value: float, unit: string, can_manage: bool>, num_likes: int, owner: record<gid: string, resource_type: string, name: string>, team: record<gid: string, resource_type: string, name: string>, time_period: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: updateGoalMetric
export def "update-goal-metric" [
  goal_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {current_number_value?: float}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/goals/{goal_gid}/setMetricCurrentValue"
    path_params: [{name: goal_gid, var: goal_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    goal_gid: $goal_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a job by id
#
# GET /jobs/{job_gid}
# Returns: record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>
# operationId: getJob
export def "get-job" [
  job_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/jobs/{job_gid}"
    path_params: [{name: job_gid, var: job_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    job_gid: $job_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an organization export request
#
# POST /organization_exports
# Returns: record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>>
# operationId: createOrganizationExport
export def "create-organization-export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # An *organization_export* request starts a job to export the complete data of the given Organization. — shape: {organization?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/organization_exports"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get details on an org export request
#
# GET /organization_exports/{organization_export_gid}
# Returns: record<data: record<gid: string, resource_type: string, created_at: string, download_url: string, organization: record<gid: string, resource_type: string, name: string>, state: string>>
# operationId: getOrganizationExport
export def "get-organization-export" [
  organization_export_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/organization_exports/{organization_export_gid}"
    path_params: [{name: organization_export_gid, var: organization_export_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    organization_export_gid: $organization_export_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple portfolio memberships
#
# GET /portfolio_memberships
# Returns: record<data: table<gid: string, resource_type: string, portfolio: record, user: record>>
# operationId: getPortfolioMemberships
export def "get-portfolio-memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --portfolio: string # The portfolio to filter results on. (e.g. 12345)
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolio_memberships"
    query: [{name: portfolio, var: portfolio}, {name: workspace, var: workspace}, {name: user, var: user}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio: $portfolio, workspace: $workspace, user: $user, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a portfolio membership
#
# GET /portfolio_memberships/{portfolio_membership_gid}
# Returns: record<data: record<gid: string, resource_type: string, portfolio: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>
# operationId: getPortfolioMembership
export def "get-portfolio-membership" [
  portfolio_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolio_memberships/{portfolio_membership_gid}"
    path_params: [{name: portfolio_membership_gid, var: portfolio_membership_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_membership_gid: $portfolio_membership_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple portfolios
#
# GET /portfolios
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getPortfolios
export def "get-portfolios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter portfolios on. (required, e.g. 1331)
  --owner: string # The user who owns the portfolio. Currently, API users can only get a list of portfolios that they themselves own. (required, e.g. 14916)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolios"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: workspace, var: workspace, required: true}, {name: owner, var: owner, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, workspace: $workspace, owner: $owner
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a portfolio
#
# POST /portfolios
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createPortfolio
export def "create-portfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", public?: bool, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a portfolio
#
# DELETE /portfolios/{portfolio_gid}
# Returns: record<data: record>
# operationId: deletePortfolio
export def "delete-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/portfolios/{portfolio_gid}"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a portfolio
#
# GET /portfolios/{portfolio_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getPortfolio
export def "get-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolios/{portfolio_gid}"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a portfolio
#
# PUT /portfolios/{portfolio_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: updatePortfolio
export def "update-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", public?: bool, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/portfolios/{portfolio_gid}"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom field to a portfolio
#
# POST /portfolios/{portfolio_gid}/addCustomFieldSetting
# Returns: record<data: record<gid: string, resource_type: string, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>>>
# operationId: addCustomFieldSettingForPortfolio
export def "add-custom-field-setting-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/addCustomFieldSetting"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a portfolio item
#
# POST /portfolios/{portfolio_gid}/addItem
# Returns: record<data: record>
# operationId: addItemForPortfolio
export def "add-item-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, item: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/addItem"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add users to a portfolio
#
# POST /portfolios/{portfolio_gid}/addMembers
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: addMembersForPortfolio
export def "add-members-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/addMembers"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a portfolio's custom fields
#
# GET /portfolios/{portfolio_gid}/custom_field_settings
# Returns: record<data: table<gid: string, resource_type: string, custom_field: record, is_important: bool, parent: record, project: record>>
# operationId: getCustomFieldSettingsForPortfolio
export def "get-custom-field-settings-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolios/{portfolio_gid}/custom_field_settings"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get portfolio items
#
# GET /portfolios/{portfolio_gid}/items
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getItemsForPortfolio
export def "get-items-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolios/{portfolio_gid}/items"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get memberships from a portfolio
#
# GET /portfolios/{portfolio_gid}/portfolio_memberships
# Returns: record<data: table<gid: string, resource_type: string, portfolio: record, user: record>>
# operationId: getPortfolioMembershipsForPortfolio
export def "get-portfolio-memberships-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/portfolios/{portfolio_gid}/portfolio_memberships"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: user, var: user}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, user: $user, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a custom field from a portfolio
#
# POST /portfolios/{portfolio_gid}/removeCustomFieldSetting
# Returns: record<data: record>
# operationId: removeCustomFieldSettingForPortfolio
export def "remove-custom-field-setting-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/removeCustomFieldSetting"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a portfolio item
#
# POST /portfolios/{portfolio_gid}/removeItem
# Returns: record<data: record>
# operationId: removeItemForPortfolio
export def "remove-item-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {item: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/removeItem"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove users from a portfolio
#
# POST /portfolios/{portfolio_gid}/removeMembers
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, custom_fields: list<record>, due_on: string, members: list<record>, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: removeMembersForPortfolio
export def "remove-members-for-portfolio" [
  portfolio_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/portfolios/{portfolio_gid}/removeMembers"
    path_params: [{name: portfolio_gid, var: portfolio_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    portfolio_gid: $portfolio_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project brief
#
# DELETE /project_briefs/{project_brief_gid}
# Returns: record<data: record>
# operationId: deleteProjectBrief
export def "delete-project-brief" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/project_briefs/{project_brief_gid}"
    path_params: [{name: project_brief_gid, var: project_brief_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_brief_gid: $project_brief_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project brief
#
# GET /project_briefs/{project_brief_gid}
# Returns: record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>
# operationId: getProjectBrief
export def "get-project-brief" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/project_briefs/{project_brief_gid}"
    path_params: [{name: project_brief_gid, var: project_brief_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_brief_gid: $project_brief_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project brief
#
# PUT /project_briefs/{project_brief_gid}
# Returns: record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>
# operationId: updateProjectBrief
export def "update-project-brief" [
  project_brief_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {html_text?: string, title?: string, text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/project_briefs/{project_brief_gid}"
    path_params: [{name: project_brief_gid, var: project_brief_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_brief_gid: $project_brief_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project membership
#
# GET /project_memberships/{project_membership_gid}
# Returns: record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>, write_access: string>>
# operationId: getProjectMembership
export def "get-project-membership" [
  project_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/project_memberships/{project_membership_gid}"
    path_params: [{name: project_membership_gid, var: project_membership_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_membership_gid: $project_membership_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project status
#
# DELETE /project_statuses/{project_status_gid}
# Returns: record<data: record>
# operationId: deleteProjectStatus
export def "delete-project-status" [
  project_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/project_statuses/{project_status_gid}"
    path_params: [{name: project_status_gid, var: project_status_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_status_gid: $project_status_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project status
#
# GET /project_statuses/{project_status_gid}
# Returns: record<data: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>>
# operationId: getProjectStatus
export def "get-project-status" [
  project_status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/project_statuses/{project_status_gid}"
    path_params: [{name: project_status_gid, var: project_status_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_status_gid: $project_status_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple project templates
#
# GET /project_templates
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjectTemplates
export def "get-project-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --workspace: string # The workspace to filter results on. (e.g. 12345)
  --team: string # The team to filter projects on. (e.g. 14916)
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/project_templates"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: workspace, var: workspace}, {name: team, var: team}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, workspace: $workspace, team: $team, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project template
#
# GET /project_templates/{project_template_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, description: string, html_description: string, owner: record<gid: string, resource_type: string, name: string>, public: bool, requested_dates: list<record>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: getProjectTemplate
export def "get-project-template" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/project_templates/{project_template_gid}"
    path_params: [{name: project_template_gid, var: project_template_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_template_gid: $project_template_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Instantiate a project from a project template
#
# POST /project_templates/{project_template_gid}/instantiateProject
# Returns: record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>
# operationId: instantiateProject
export def "instantiate-project" [
  project_template_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {is_strict?: bool, name: string, public: bool, requested_dates?: list, team?: string, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/project_templates/{project_template_gid}/instantiateProject"
    path_params: [{name: project_template_gid, var: project_template_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_template_gid: $project_template_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple projects
#
# GET /projects
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjects
export def "get-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace or organization to filter projects on. (e.g. 1331)
  --team: string # The team to filter projects on. (e.g. 14916)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: workspace, var: workspace}, {name: team, var: team}, {name: archived, var: archived}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, workspace: $workspace, team: $team, archived: $archived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project
#
# POST /projects
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: createProject
export def "create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, archived?: bool, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", current_status?: record, current_status_update?: record, default_view?: "list"|"board"|"calendar"|"timeline", due_date?: string, due_on?: string, html_notes?: string, is_template?: bool, notes?: string, ... (7 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project
#
# DELETE /projects/{project_gid}
# Returns: record<data: record>
# operationId: deleteProject
export def "delete-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/projects/{project_gid}"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project
#
# GET /projects/{project_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: getProject
export def "get-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a project
#
# PUT /projects/{project_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: updateProject
export def "update-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, archived?: bool, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", current_status?: record, current_status_update?: record, default_view?: "list"|"board"|"calendar"|"timeline", due_date?: string, due_on?: string, html_notes?: string, is_template?: bool, notes?: string, ... (7 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/projects/{project_gid}"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a custom field to a project
#
# POST /projects/{project_gid}/addCustomFieldSetting
# Returns: record<data: record<gid: string, resource_type: string, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>, is_important: bool, parent: record<gid: string, resource_type: string, name: string>, project: record<gid: string, resource_type: string, name: string>>>
# operationId: addCustomFieldSettingForProject
export def "add-custom-field-setting-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string, insert_after?: string, insert_before?: string, is_important?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/addCustomFieldSetting"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add followers to a project
#
# POST /projects/{project_gid}/addFollowers
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: addFollowersForProject
export def "add-followers-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/addFollowers"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add users to a project
#
# POST /projects/{project_gid}/addMembers
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: addMembersForProject
export def "add-members-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/addMembers"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project's custom fields
#
# GET /projects/{project_gid}/custom_field_settings
# Returns: record<data: table<gid: string, resource_type: string, custom_field: record, is_important: bool, parent: record, project: record>>
# operationId: getCustomFieldSettingsForProject
export def "get-custom-field-settings-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/custom_field_settings"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate a project
#
# POST /projects/{project_gid}/duplicate
# Returns: record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>
# operationId: duplicateProject
export def "duplicate-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {include?: "members"|"notes"|"forms"|"task_notes"|"task_assignee"|"task_subtasks"|"task_attachments"|"task_dates"|"task_dependencies"|"task_followers"|"task_tags"|"task_projects", name: string, schedule_dates?: record, team?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/duplicate"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project brief
#
# POST /projects/{project_gid}/project_briefs
# Returns: record<data: record<gid: string, resource_type: string, html_text: string, title: string, permalink_url: string, project: record<gid: string, resource_type: string, name: string>, text: string>>
# operationId: createProjectBrief
export def "create-project-brief" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {html_text?: string, title?: string, text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/project_briefs"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get memberships from a project
#
# GET /projects/{project_gid}/project_memberships
# Returns: record<data: table<gid: string, resource_type: string, user: record>>
# operationId: getProjectMembershipsForProject
export def "get-project-memberships-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/project_memberships"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: user, var: user}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, user: $user, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get statuses from a project
#
# GET /projects/{project_gid}/project_statuses
# Returns: record<data: table<gid: string, resource_type: string, title: string>>
# operationId: getProjectStatusesForProject
export def "get-project-statuses-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/project_statuses"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project status
#
# POST /projects/{project_gid}/project_statuses
# Returns: record<data: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, modified_at: string>>
# operationId: createProjectStatusForProject
export def "create-project-status-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {title?: string, color: "green"|"yellow"|"red"|"blue", html_text?: string, text: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/project_statuses"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a custom field from a project
#
# POST /projects/{project_gid}/removeCustomFieldSetting
# Returns: record<data: record>
# operationId: removeCustomFieldSettingForProject
export def "remove-custom-field-setting-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --data: record # shape: {custom_field: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/removeCustomFieldSetting"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove followers from a project
#
# POST /projects/{project_gid}/removeFollowers
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: removeFollowersForProject
export def "remove-followers-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/removeFollowers"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove users from a project
#
# POST /projects/{project_gid}/removeMembers
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: removeMembersForProject
export def "remove-members-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {members: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/removeMembers"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project template from a project
#
# POST /projects/{project_gid}/saveAsTemplate
# Returns: record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>
# operationId: projectSaveAsTemplate
export def "project-save-as-template" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {name: string, public: bool, team?: string, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/saveAsTemplate"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get sections in a project
#
# GET /projects/{project_gid}/sections
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getSectionsForProject
export def "get-sections-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/sections"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a section in a project
#
# POST /projects/{project_gid}/sections
# Returns: record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>
# operationId: createSectionForProject
export def "create-section-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/sections"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move or Insert sections
#
# POST /projects/{project_gid}/sections/insert
# Returns: record<data: record>
# operationId: insertSectionForProject
export def "insert-section-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {after_section?: string, before_section?: string, project: string, section: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{project_gid}/sections/insert"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get task count of a project
#
# GET /projects/{project_gid}/task_counts
# Returns: record<data: record<num_completed_milestones: int, num_completed_tasks: int, num_incomplete_milestones: int, num_incomplete_tasks: int, num_milestones: int, num_tasks: int>>
# operationId: getTaskCountsForProject
export def "get-task-counts-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/task_counts"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks from a project
#
# GET /projects/{project_gid}/tasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getTasksForProject
export def "get-tasks-for-project" [
  project_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*. (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{project_gid}/tasks"
    path_params: [{name: project_gid, var: project_gid}]
    query: [{name: completed_since, var: completed_since}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    project_gid: $project_gid, completed_since: $completed_since, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a section
#
# DELETE /sections/{section_gid}
# Returns: record<data: record>
# operationId: deleteSection
export def "delete-section" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/sections/{section_gid}"
    path_params: [{name: section_gid, var: section_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section_gid: $section_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a section
#
# GET /sections/{section_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>
# operationId: getSection
export def "get-section" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sections/{section_gid}"
    path_params: [{name: section_gid, var: section_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section_gid: $section_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a section
#
# PUT /sections/{section_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, created_at: string, project: record<gid: string, resource_type: string, name: string>, projects: list<record>>>
# operationId: updateSection
export def "update-section" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, name: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/sections/{section_gid}"
    path_params: [{name: section_gid, var: section_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section_gid: $section_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add task to section
#
# POST /sections/{section_gid}/addTask
# Returns: record<data: record>
# operationId: addTaskForSection
export def "add-task-for-section" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, task: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/sections/{section_gid}/addTask"
    path_params: [{name: section_gid, var: section_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section_gid: $section_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks from a section
#
# GET /sections/{section_gid}/tasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getTasksForSection
export def "get-tasks-for-section" [
  section_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sections/{section_gid}/tasks"
    path_params: [{name: section_gid, var: section_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    section_gid: $section_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get status updates from an object
#
# GET /status_updates
# Returns: record<data: table<gid: string, resource_type: string, resource_subtype: string, title: string>>
# operationId: getStatusesForObject
export def "get-statuses-for-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --parent: string # Globally unique identifier for object to fetch statuses from. Must be a GID for a project, portfolio, or goal. (required, e.g. 159874)
  --created-since: string # Only return statuses that have been created since the given time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/status_updates"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: parent, var: parent, required: true}, {name: created_since, var: created_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, parent: $parent, created_since: $created_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a status update
#
# POST /status_updates
# Returns: record<data: record<gid: string, resource_type: string, resource_subtype: string, title: string, html_text: string, status_type: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>>
# operationId: createStatusForObject
export def "create-status-for-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {title?: string, html_text?: string, status_type: "on_track"|"at_risk"|"off_track"|"on_hold"|"complete"|"achieved"|"partial"|"missed"|"dropped", text: string, parent: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/status_updates"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a status update
#
# DELETE /status_updates/{status_gid}
# Returns: record<data: record>
# operationId: deleteStatus
export def "delete-status" [
  status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/status_updates/{status_gid}"
    path_params: [{name: status_gid, var: status_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status_gid: $status_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a status update
#
# GET /status_updates/{status_gid}
# Returns: record<data: record<gid: string, resource_type: string, resource_subtype: string, title: string, html_text: string, status_type: string, text: string, author: record<gid: string, resource_type: string, name: string>, created_at: string, created_by: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, liked: bool, likes: list<record>, modified_at: string, num_hearts: int, num_likes: int, parent: record<gid: string, resource_type: string, name: string>>>
# operationId: getStatus
export def "get-status" [
  status_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/status_updates/{status_gid}"
    path_params: [{name: status_gid, var: status_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    status_gid: $status_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a story
#
# DELETE /stories/{story_gid}
# Returns: record<data: record>
# operationId: deleteStory
export def "delete-story" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/stories/{story_gid}"
    path_params: [{name: story_gid, var: story_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_gid: $story_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a story
#
# GET /stories/{story_gid}
# Returns: record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>
# operationId: getStory
export def "get-story" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/stories/{story_gid}"
    path_params: [{name: story_gid, var: story_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_gid: $story_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a story
#
# PUT /stories/{story_gid}
# Returns: record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>
# operationId: updateStory
export def "update-story" [
  story_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love", text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/stories/{story_gid}"
    path_params: [{name: story_gid, var: story_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    story_gid: $story_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple tags
#
# GET /tags
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getTags
export def "get-tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to filter tags on. (e.g. 1331)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a tag
#
# POST /tags
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createTag
export def "create-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", notes?: string, followers?: list<string>, workspace?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tags"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a tag
#
# DELETE /tags/{tag_gid}
# Returns: record<data: record>
# operationId: deleteTag
export def "delete-tag" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tags/{tag_gid}"
    path_params: [{name: tag_gid, var: tag_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_gid: $tag_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a tag
#
# GET /tags/{tag_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getTag
export def "get-tag" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tag_gid}"
    path_params: [{name: tag_gid, var: tag_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_gid: $tag_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a tag
#
# PUT /tags/{tag_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: updateTag
export def "update-tag" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: put
    path: "/tags/{tag_gid}"
    path_params: [{name: tag_gid, var: tag_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_gid: $tag_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks from a tag
#
# GET /tags/{tag_gid}/tasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getTasksForTag
export def "get-tasks-for-tag" [
  tag_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tags/{tag_gid}/tasks"
    path_params: [{name: tag_gid, var: tag_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tag_gid: $tag_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple tasks
#
# GET /tasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getTasks
export def "get-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --assignee: string # The assignee to filter tasks on. If searching for unassigned tasks, assignee.any = null can be specified. *Note: If you specify `assignee`, you must also specify the `workspace` to filter on.* (e.g. 14641)
  --project: string # The project to filter tasks on. (e.g. 321654)
  --section: string # The section to filter tasks on. *Note: Currently, this is only supported in board views.* (e.g. 321654)
  --workspace: string # The workspace to filter tasks on. *Note: If you specify `workspace`, you must also specify the `assignee` to filter on.* (e.g. 321654)
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
  --modified-since: string # Only return tasks that have been modified since the given time. *Note: A task is considered “modified” if any of its properties change, or associations between it and other objects are modified (e.g. a task being added to a project). A task is not considered modified just because another object it is associated with (e.g. a subtask) is modified. Actions that count as modifying the task include assigning, renaming, completing, and adding stories.* (format: date-time, e.g. 2012-02-22T02:06:58.158Z)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: assignee, var: assignee}, {name: project, var: project}, {name: section, var: section}, {name: workspace, var: workspace}, {name: completed_since, var: completed_since}, {name: modified_since, var: modified_since}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, assignee: $assignee, project: $project, section: $section, workspace: $workspace, completed_since: $completed_since, modified_since: $modified_since
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a task
#
# POST /tasks
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createTask
export def "create-task" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, resource_subtype?: "default_task"|"milestone"|"section"|"approval", approval_status?: "pending"|"approved"|"rejected"|"changes_requested", assignee_status?: "today"|"upcoming"|"later"|"new"|"inbox", completed?: bool, completed_by?: record, due_at?: string, due_on?: string, external?: record, html_notes?: string, liked?: bool, notes?: string, start_at?: string, start_on?: string, assignee?: string, assignee_section?: string, custom_fields?: record, followers?: list<string>, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a task
#
# DELETE /tasks/{task_gid}
# Returns: record<data: record>
# operationId: deleteTask
export def "delete-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/tasks/{task_gid}"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a task
#
# GET /tasks/{task_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getTask
export def "get-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a task
#
# PUT /tasks/{task_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: updateTask
export def "update-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, resource_subtype?: "default_task"|"milestone"|"section"|"approval", approval_status?: "pending"|"approved"|"rejected"|"changes_requested", assignee_status?: "today"|"upcoming"|"later"|"new"|"inbox", completed?: bool, completed_by?: record, due_at?: string, due_on?: string, external?: record, html_notes?: string, liked?: bool, notes?: string, start_at?: string, start_on?: string, assignee?: string, assignee_section?: string, custom_fields?: record, followers?: list<string>, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/tasks/{task_gid}"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set dependencies for a task
#
# POST /tasks/{task_gid}/addDependencies
# Returns: record<data: record>
# operationId: addDependenciesForTask
export def "add-dependencies-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/addDependencies"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set dependents for a task
#
# POST /tasks/{task_gid}/addDependents
# Returns: record<data: record>
# operationId: addDependentsForTask
export def "add-dependents-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/addDependents"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add followers to a task
#
# POST /tasks/{task_gid}/addFollowers
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: addFollowersForTask
export def "add-followers-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/addFollowers"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a project to a task
#
# POST /tasks/{task_gid}/addProject
# Returns: record<data: record>
# operationId: addProjectForTask
export def "add-project-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, project: string, section?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/addProject"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a tag to a task
#
# POST /tasks/{task_gid}/addTag
# Returns: record<data: record>
# operationId: addTagForTask
export def "add-tag-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/addTag"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dependencies from a task
#
# GET /tasks/{task_gid}/dependencies
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getDependenciesForTask
export def "get-dependencies-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/dependencies"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get dependents from a task
#
# GET /tasks/{task_gid}/dependents
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getDependentsForTask
export def "get-dependents-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/dependents"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Duplicate a task
#
# POST /tasks/{task_gid}/duplicate
# Returns: record<data: record<gid: string, resource_type: string, new_project: record<gid: string, resource_type: string, name: string>, new_project_template: record<gid: string, resource_type: string, name: string>, new_task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, resource_subtype: string, status: string>>
# operationId: duplicateTask
export def "duplicate-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {include?: "notes"|"assignee"|"subtasks"|"attachments"|"tags"|"followers"|"projects"|"dates"|"dependencies"|"parent", name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/duplicate"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get projects a task is in
#
# GET /tasks/{task_gid}/projects
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjectsForTask
export def "get-projects-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/projects"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlink dependencies from a task
#
# POST /tasks/{task_gid}/removeDependencies
# Returns: record<data: record>
# operationId: removeDependenciesForTask
export def "remove-dependencies-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # e.g. {dependencies: [133713, 184253]} — shape: {dependencies?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/removeDependencies"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unlink dependents from a task
#
# POST /tasks/{task_gid}/removeDependents
# Returns: record<data: record>
# operationId: removeDependentsForTask
export def "remove-dependents-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A set of dependent tasks. (e.g. {dependents: [133713, 184253]}) — shape: {dependents?: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/removeDependents"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove followers from a task
#
# POST /tasks/{task_gid}/removeFollowers
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: removeFollowerForTask
export def "remove-follower-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {followers: list<string>}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/removeFollowers"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a project from a task
#
# POST /tasks/{task_gid}/removeProject
# Returns: record<data: record>
# operationId: removeProjectForTask
export def "remove-project-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {project: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/removeProject"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a tag from a task
#
# POST /tasks/{task_gid}/removeTag
# Returns: record<data: record>
# operationId: removeTagForTask
export def "remove-tag-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {tag: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/removeTag"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the parent of a task
#
# POST /tasks/{task_gid}/setParent
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: setParentForTask
export def "set-parent-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {insert_after?: string, insert_before?: string, parent: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/setParent"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get stories from a task
#
# GET /tasks/{task_gid}/stories
# Returns: record<data: table<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>>
# operationId: getStoriesForTask
export def "get-stories-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/stories"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a story on a task
#
# POST /tasks/{task_gid}/stories
# Returns: record<data: record<gid: string, resource_type: string, created_at: string, html_text: string, is_pinned: bool, resource_subtype: string, sticker_name: string, text: string, assignee: record<gid: string, resource_type: string, name: string>, created_by: record<gid: string, resource_type: string, name: string>, custom_field: record<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string>, dependency: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicate_of: record<gid: string, resource_type: string, name: string, resource_subtype: string>, duplicated_from: record<gid: string, resource_type: string, name: string, resource_subtype: string>, follower: record<gid: string, resource_type: string, name: string>, hearted: bool, hearts: list<record>, is_editable: bool, is_edited: bool, liked: bool, likes: list<record>, new_approval_status: string, new_date_value: record<due_at: string, due_on: string, start_on: string>, new_dates: record<due_at: string, due_on: string, start_on: string>, new_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, new_multi_enum_values: list<record>, new_name: string, new_number_value: int, new_people_value: list<record>, new_resource_subtype: string, new_section: record<gid: string, resource_type: string, name: string>, new_text_value: string, num_hearts: int, num_likes: int, old_approval_status: string, old_date_value: record<due_at: string, due_on: string, start_on: string>, old_dates: record<due_at: string, due_on: string, start_on: string>, old_enum_value: record<gid: string, resource_type: string, color: string, enabled: bool, name: string>, old_multi_enum_values: list<record>, old_name: string, old_number_value: int, old_people_value: list<record>, old_resource_subtype: string, old_section: record<gid: string, resource_type: string, name: string>, old_text_value: string, previews: list<record>, project: record<gid: string, resource_type: string, name: string>, source: string, story: record<gid: string, resource_type: string, created_at: string, created_by: record, resource_subtype: string, text: string>, tag: record<gid: string, resource_type: string, name: string>, target: record<gid: string, resource_type: string, name: string, resource_subtype: string>, task: record<gid: string, resource_type: string, name: string, resource_subtype: string>, type: string>>
# operationId: createStoryForTask
export def "create-story-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {html_text?: string, is_pinned?: bool, sticker_name?: "green_checkmark"|"people_dancing"|"dancing_unicorn"|"heart"|"party_popper"|"people_waving_flags"|"splashing_narwhal"|"trophy"|"yeti_riding_unicorn"|"celebrating_people"|"determined_climbers"|"phoenix_spreading_love", text?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/stories"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get subtasks from a task
#
# GET /tasks/{task_gid}/subtasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getSubtasksForTask
export def "get-subtasks-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/subtasks"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a subtask
#
# POST /tasks/{task_gid}/subtasks
# Returns: record<data: record<gid: string, resource_type: string, name: string, resource_subtype: string, actual_time_minutes: float, approval_status: string, assignee_status: string, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_at: string, dependencies: list<record>, dependents: list<record>, due_at: string, due_on: string, external: record<data: string, gid: string>, hearted: bool, hearts: list<record>, html_notes: string, is_rendered_as_separator: bool, liked: bool, likes: list<record>, memberships: list<record>, modified_at: string, notes: string, num_hearts: int, num_likes: int, num_subtasks: int, start_at: string, start_on: string, assignee: record<gid: string, resource_type: string, name: string>, assignee_section: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, parent: record<gid: string, resource_type: string, name: string, resource_subtype: string>, permalink_url: string, projects: list<record>, tags: list<record>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createSubtaskForTask
export def "create-subtask-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, resource_subtype?: "default_task"|"milestone"|"section"|"approval", approval_status?: "pending"|"approved"|"rejected"|"changes_requested", assignee_status?: "today"|"upcoming"|"later"|"new"|"inbox", completed?: bool, completed_by?: record, due_at?: string, due_on?: string, external?: record, html_notes?: string, liked?: bool, notes?: string, start_at?: string, start_on?: string, assignee?: string, assignee_section?: string, custom_fields?: record, followers?: list<string>, ... (4 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/tasks/{task_gid}/subtasks"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a task's tags
#
# GET /tasks/{task_gid}/tags
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getTagsForTask
export def "get-tags-for-task" [
  task_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/tasks/{task_gid}/tags"
    path_params: [{name: task_gid, var: task_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    task_gid: $task_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get team memberships
#
# GET /team_memberships
# Returns: record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>
# operationId: getTeamMemberships
export def "get-team-memberships" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --team: string # Globally unique identifier for the team. (e.g. 159874)
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. This parameter must be used with the workspace parameter. (e.g. 512241)
  --workspace: string # Globally unique identifier for the workspace. This parameter must be used with the user parameter. (e.g. 31326)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team_memberships"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: team, var: team}, {name: user, var: user}, {name: workspace, var: workspace}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, team: $team, user: $user, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team membership
#
# GET /team_memberships/{team_membership_gid}
# Returns: record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>
# operationId: getTeamMembership
export def "get-team-membership" [
  team_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/team_memberships/{team_membership_gid}"
    path_params: [{name: team_membership_gid, var: team_membership_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_membership_gid: $team_membership_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a team
#
# POST /teams
# Returns: record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>
# operationId: createTeam
export def "create-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, description?: string, html_description?: string, organization?: string, visibility?: "secret"|"request_to_join"|"public"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a team
#
# PUT /teams
# Returns: record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>
# operationId: updateTeam
export def "update-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, description?: string, html_description?: string, organization?: string, visibility?: "secret"|"request_to_join"|"public"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/teams"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team
#
# GET /teams/{team_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, description: string, html_description: string, organization: record<gid: string, resource_type: string, name: string>, permalink_url: string, visibility: string>>
# operationId: getTeam
export def "get-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_gid}"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to a team
#
# POST /teams/{team_gid}/addUser
# Returns: record<data: record<gid: string, resource_type: string, is_guest: bool, team: record<gid: string, resource_type: string, name: string>, user: record<gid: string, resource_type: string, name: string>>>
# operationId: addUserForTeam
export def "add-user-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{team_gid}/addUser"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team's project templates
#
# GET /teams/{team_gid}/project_templates
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjectTemplatesForTeam
export def "get-project-templates-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_gid}/project_templates"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a team's projects
#
# GET /teams/{team_gid}/projects
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjectsForTeam
export def "get-projects-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_gid}/projects"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: archived, var: archived}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, archived: $archived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project in a team
#
# POST /teams/{team_gid}/projects
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: createProjectForTeam
export def "create-project-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, archived?: bool, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", current_status?: record, current_status_update?: record, default_view?: "list"|"board"|"calendar"|"timeline", due_date?: string, due_on?: string, html_notes?: string, is_template?: bool, notes?: string, ... (7 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{team_gid}/projects"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from a team
#
# POST /teams/{team_gid}/removeUser
# Returns: record<data: record>
# operationId: removeUserForTeam
export def "remove-user-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/teams/{team_gid}/removeUser"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get memberships from a team
#
# GET /teams/{team_gid}/team_memberships
# Returns: record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>
# operationId: getTeamMembershipsForTeam
export def "get-team-memberships-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_gid}/team_memberships"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users in a team
#
# GET /teams/{team_gid}/users
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getUsersForTeam
export def "get-users-for-team" [
  team_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/teams/{team_gid}/users"
    path_params: [{name: team_gid, var: team_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    team_gid: $team_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get time periods
#
# GET /time_periods
# Returns: record<data: table<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>>
# operationId: getTimePeriods
export def "get-time-periods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --start-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --end-on: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --workspace: string # Globally unique identifier for the workspace. (required, e.g. 31326)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/time_periods"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: start_on, var: start_on}, {name: end_on, var: end_on}, {name: workspace, var: workspace, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, start_on: $start_on, end_on: $end_on, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a time period
#
# GET /time_periods/{time_period_gid}
# Returns: record<data: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string, parent: record<gid: string, resource_type: string, display_name: string, end_on: string, period: string, start_on: string>>>
# operationId: getTimePeriod
export def "get-time-period" [
  time_period_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/time_periods/{time_period_gid}"
    path_params: [{name: time_period_gid, var: time_period_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    time_period_gid: $time_period_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user task list
#
# GET /user_task_lists/{user_task_list_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getUserTaskList
export def "get-user-task-list" [
  user_task_list_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user_task_lists/{user_task_list_gid}"
    path_params: [{name: user_task_list_gid, var: user_task_list_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_task_list_gid: $user_task_list_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tasks from a user task list
#
# GET /user_task_lists/{user_task_list_gid}/tasks
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: getTasksForUserTaskList
export def "get-tasks-for-user-task-list" [
  user_task_list_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --completed-since: string # Only return tasks that are either incomplete or that have been completed since this time. Accepts a date-time string or the keyword *now*. (e.g. 2012-02-22T02:06:58.158Z)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/user_task_lists/{user_task_list_gid}/tasks"
    path_params: [{name: user_task_list_gid, var: user_task_list_gid}]
    query: [{name: completed_since, var: completed_since}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_task_list_gid: $user_task_list_gid, completed_since: $completed_since, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple users
#
# GET /users
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getUsers
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
  --workspace: string # The workspace or organization ID to filter users on. (e.g. 1331)
  --team: string # The team ID to filter users on. (e.g. 15627)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users"
    query: [{name: workspace, var: workspace}, {name: team, var: team}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace: $workspace, team: $team, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user
#
# GET /users/{user_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, email: string, photo: record<image_1024x1024: string, image_128x128: string, image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string>, workspaces: list<record>>>
# operationId: getUser
export def "get-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's favorites
#
# GET /users/{user_gid}/favorites
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getFavoritesForUser
export def "get-favorites-for-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --resource-type: string@resource-type-completer # The resource type of favorites to be returned. (required, default: project)
  --workspace: string # The workspace in which to get favorites. (required, e.g. 1234)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}/favorites"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: resource_type, var: resource_type, required: true, default: project}, {name: workspace, var: workspace, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, resource_type: $resource_type, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get memberships from a user
#
# GET /users/{user_gid}/team_memberships
# Returns: record<data: table<gid: string, resource_type: string, is_guest: bool, team: record, user: record>>
# operationId: getTeamMembershipsForUser
export def "get-team-memberships-for-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # Globally unique identifier for the workspace. (required, e.g. 31326)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}/team_memberships"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: workspace, var: workspace, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get teams for a user
#
# GET /users/{user_gid}/teams
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getTeamsForUser
export def "get-teams-for-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --organization: string # The workspace or organization to filter teams on. (required, e.g. 1331)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}/teams"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: organization, var: organization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, organization: $organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a user's task list
#
# GET /users/{user_gid}/user_task_list
# Returns: record<data: record<gid: string, resource_type: string, name: string, owner: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: getUserTaskListForUser
export def "get-user-task-list-for-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --workspace: string # The workspace in which to get the user task list. (required, e.g. 1234)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}/user_task_list"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: workspace, var: workspace, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, workspace: $workspace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get workspace memberships for a user
#
# GET /users/{user_gid}/workspace_memberships
# Returns: record<data: table<gid: string, resource_type: string, user: record, workspace: record>>
# operationId: getWorkspaceMembershipsForUser
export def "get-workspace-memberships-for-user" [
  user_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_gid}/workspace_memberships"
    path_params: [{name: user_gid, var: user_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_gid: $user_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple webhooks
#
# GET /webhooks
# Returns: record<data: table<gid: string, resource_type: string, active: bool, resource: record, target: string, created_at: string, filters: list, last_failure_at: string, last_failure_content: string, last_success_at: string>>
# operationId: getWebhooks
export def "get-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --workspace: string # The workspace to query for webhooks in. (required, e.g. 1331)
  --resource: string # Only return webhooks for the given resource. (e.g. 51648)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: workspace, var: workspace, required: true}, {name: resource, var: resource}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, workspace: $workspace, resource: $resource
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Establish a webhook
#
# POST /webhooks
# Returns: record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>
# operationId: createWebhook
export def "create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {filters?: list, resource: string, target: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/webhooks"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a webhook
#
# DELETE /webhooks/{webhook_gid}
# Returns: record<data: record>
# operationId: deleteWebhook
export def "delete-webhook" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/webhooks/{webhook_gid}"
    path_params: [{name: webhook_gid, var: webhook_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_gid: $webhook_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a webhook
#
# GET /webhooks/{webhook_gid}
# Returns: record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>
# operationId: getWebhook
export def "get-webhook" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/webhooks/{webhook_gid}"
    path_params: [{name: webhook_gid, var: webhook_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_gid: $webhook_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a webhook
#
# PUT /webhooks/{webhook_gid}
# Returns: record<data: record<gid: string, resource_type: string, active: bool, resource: record<gid: string, resource_type: string, name: string>, target: string, created_at: string, filters: list<record>, last_failure_at: string, last_failure_content: string, last_success_at: string>>
# operationId: updateWebhook
export def "update-webhook" [
  webhook_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # shape: {filters?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/webhooks/{webhook_gid}"
    path_params: [{name: webhook_gid, var: webhook_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    webhook_gid: $webhook_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workspace membership
#
# GET /workspace_memberships/{workspace_membership_gid}
# Returns: record<data: record<gid: string, resource_type: string, user: record<gid: string, resource_type: string, name: string>, workspace: record<gid: string, resource_type: string, name: string>, is_active: bool, is_admin: bool, is_guest: bool, user_task_list: record<gid: string, resource_type: string, name: string, owner: record, workspace: record>, vacation_dates: record<end_on: string, start_on: string>>>
# operationId: getWorkspaceMembership
export def "get-workspace-membership" [
  workspace_membership_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspace_memberships/{workspace_membership_gid}"
    path_params: [{name: workspace_membership_gid, var: workspace_membership_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_membership_gid: $workspace_membership_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get multiple workspaces
#
# GET /workspaces
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getWorkspaces
export def "get-workspaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces"
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workspace
#
# GET /workspaces/{workspace_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>>
# operationId: getWorkspace
export def "get-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a workspace
#
# PUT /workspaces/{workspace_gid}
# Returns: record<data: record<gid: string, resource_type: string, name: string, email_domains: list<string>, is_organization: bool>>
# operationId: updateWorkspace
export def "update-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/workspaces/{workspace_gid}"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a user to a workspace or organization
#
# POST /workspaces/{workspace_gid}/addUser
# Returns: record<data: record<gid: string, resource_type: string, name: string, email: string, photo: record<image_1024x1024: string, image_128x128: string, image_21x21: string, image_27x27: string, image_36x36: string, image_60x60: string>>>
# operationId: addUserForWorkspace
export def "add-user-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace_gid}/addUser"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get audit log events
#
# GET /workspaces/{workspace_gid}/audit_log_events
# Returns: record<data: table<actor: record, context: record, created_at: string, details: record, event_category: string, event_type: string, gid: string, resource: record>>
# operationId: getAuditLogEvents
export def "get-audit-log-events" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Filter to events created after this time (inclusive). (format: date-time)
  --end-at: string # Filter to events created before this time (exclusive). (format: date-time)
  --event-type: string # Filter to events of this type. Refer to the [Supported AuditLogEvents](/docs/supported-auditlogevents) for a full list of values.
  --actor-type: string@actor-type-completer # Filter to events with an actor of this type. This only needs to be included if querying for actor types without an ID. If `actor_gid` is included, this should be excluded.
  --actor-gid: string # Filter to events triggered by the actor with this ID.
  --resource-gid: string # Filter to events with this resource ID.
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/audit_log_events"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: start_at, var: start_at}, {name: end_at, var: end_at}, {name: event_type, var: event_type}, {name: actor_type, var: actor_type}, {name: actor_gid, var: actor_gid}, {name: resource_gid, var: resource_gid}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, start_at: $start_at, end_at: $end_at, event_type: $event_type, actor_type: $actor_type, actor_gid: $actor_gid, resource_gid: $resource_gid, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a workspace's custom fields
#
# GET /workspaces/{workspace_gid}/custom_fields
# Returns: record<data: table<gid: string, resource_type: string, date_value: record, display_value: string, enabled: bool, enum_options: list, enum_value: record, multi_enum_values: list, name: string, number_value: float, resource_subtype: string, text_value: string, type: string, asana_created_field: string, currency_code: string, custom_label: string, custom_label_position: string, description: string, format: string, has_notifications_enabled: bool, is_global_to_workspace: bool, precision: int, created_by: record, people_value: list>>
# operationId: getCustomFieldsForWorkspace
export def "get-custom-fields-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/custom_fields"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all projects in a workspace
#
# GET /workspaces/{workspace_gid}/projects
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getProjectsForWorkspace
export def "get-projects-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
  --archived: oneof<nothing, bool> # Only return projects whose `archived` field takes on the value of this parameter. (e.g. false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/projects"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}, {name: archived, var: archived}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset, archived: $archived
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a project in a workspace
#
# POST /workspaces/{workspace_gid}/projects
# Returns: record<data: record<gid: string, resource_type: string, name: string, archived: bool, color: string, created_at: string, current_status: record<gid: string, resource_type: string, title: string, color: string, html_text: string, text: string, author: record, created_at: string, created_by: record, modified_at: string>, current_status_update: record<gid: string, resource_type: string, resource_subtype: string, title: string>, custom_field_settings: list<record>, default_view: string, due_date: string, due_on: string, html_notes: string, is_template: bool, members: list<record>, modified_at: string, notes: string, public: bool, start_on: string, workspace: record<gid: string, resource_type: string, name: string>, completed: bool, completed_at: string, completed_by: record<gid: string, resource_type: string, name: string>, created_from_template: record<gid: string, resource_type: string, name: string>, custom_fields: list<record>, followers: list<record>, icon: string, owner: record<gid: string, resource_type: string, name: string>, permalink_url: string, project_brief: record<gid: string, resource_type: string>, team: record<gid: string, resource_type: string, name: string>>>
# operationId: createProjectForWorkspace
export def "create-project-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, archived?: bool, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", current_status?: record, current_status_update?: record, default_view?: "list"|"board"|"calendar"|"timeline", due_date?: string, due_on?: string, html_notes?: string, is_template?: bool, notes?: string, ... (7 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace_gid}/projects"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a user from a workspace or organization
#
# POST /workspaces/{workspace_gid}/removeUser
# Returns: record<data: record>
# operationId: removeUserForWorkspace
export def "remove-user-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A user identification object for specification with the addUser/removeUser endpoints. — shape: {user?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace_gid}/removeUser"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get tags in a workspace
#
# GET /workspaces/{workspace_gid}/tags
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getTagsForWorkspace
export def "get-tags-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/tags"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a tag in a workspace
#
# POST /workspaces/{workspace_gid}/tags
# Returns: record<data: record<gid: string, resource_type: string, name: string, color: string, notes: string, created_at: string, followers: list<record>, permalink_url: string, workspace: record<gid: string, resource_type: string, name: string>>>
# operationId: createTagForWorkspace
export def "create-tag-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --data: record # A generic Asana Resource, containing a globally unique identifier. — shape: {name?: string, color?: "dark-pink"|"dark-green"|"dark-blue"|"dark-red"|"dark-teal"|"dark-brown"|"dark-orange"|"dark-purple"|"dark-warm-gray"|"light-pink"|"light-green"|"light-blue"|"light-red"|"light-teal"|"light-brown"|"light-orange"|"light-purple"|"light-warm-gray", notes?: string, workspace?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/workspaces/{workspace_gid}/tags"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search tasks in a workspace
#
# GET /workspaces/{workspace_gid}/tasks/search
# Returns: record<data: table<gid: string, resource_type: string, name: string, resource_subtype: string>>
# operationId: searchTasksForWorkspace
export def "search-tasks-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --text: string # Performs full-text search on both task name and description (e.g. Bug)
  --resource-subtype: string@resource-subtype-completer-1 # Filters results by the task's resource_subtype (default: milestone)
  --assignee-any: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assignee-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --portfolios-any: string # Comma-separated list of portfolio IDs (e.g. 12345,23456,34567)
  --projects-any: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --projects-not: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --projects-all: string # Comma-separated list of project IDs (e.g. 12345,23456,34567)
  --sections-any: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --sections-not: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --sections-all: string # Comma-separated list of section or column IDs (e.g. 12345,23456,34567)
  --tags-any: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --tags-not: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --tags-all: string # Comma-separated list of tag IDs (e.g. 12345,23456,34567)
  --teams-any: string # Comma-separated list of team IDs (e.g. 12345,23456,34567)
  --followers-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --created-by-any: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --created-by-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assigned-by-any: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --assigned-by-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --liked-by-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --commented-on-by-not: string # Comma-separated list of user identifiers (e.g. 12345,23456,34567)
  --due-on-before: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --due-on-after: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --due-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --due-at-before: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --due-at-after: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --start-on-before: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --start-on-after: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --start-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --created-on-before: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --created-on-after: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --created-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --created-at-before: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --created-at-after: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --completed-on-before: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --completed-on-after: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --completed-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --completed-at-before: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --completed-at-after: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --modified-on-before: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --modified-on-after: string # ISO 8601 date string (format: date, e.g. 2019-09-15)
  --modified-on: string # ISO 8601 date string or `null` (nullable, format: date, e.g. 2019-09-15)
  --modified-at-before: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --modified-at-after: string # ISO 8601 datetime string (format: date-time, e.g. 2019-04-15T01:01:46.055Z)
  --is-blocking: oneof<nothing, bool> # Filter to incomplete tasks with dependents (e.g. false)
  --is-blocked: oneof<nothing, bool> # Filter to tasks with incomplete dependencies (e.g. false)
  --has-attachment: oneof<nothing, bool> # Filter to tasks with attachments (e.g. false)
  --completed: oneof<nothing, bool> # Filter to completed tasks (e.g. false)
  --is-subtask: oneof<nothing, bool> # Filter to subtasks (e.g. false)
  --sort-by: string@sort-by-completer # One of `due_date`, `created_at`, `completed_at`, `likes`, or `modified_at`, defaults to `modified_at` (default: modified_at, e.g. likes)
  --sort-ascending: oneof<nothing, bool> # Default `false` (default: false, e.g. true)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/tasks/search"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: text, var: text}, {name: resource_subtype, var: resource_subtype}, {name: "assignee.any", var: assignee_any}, {name: "assignee.not", var: assignee_not}, {name: "portfolios.any", var: portfolios_any}, {name: "projects.any", var: projects_any}, {name: "projects.not", var: projects_not}, {name: "projects.all", var: projects_all}, {name: "sections.any", var: sections_any}, {name: "sections.not", var: sections_not}, {name: "sections.all", var: sections_all}, {name: "tags.any", var: tags_any}, {name: "tags.not", var: tags_not}, {name: "tags.all", var: tags_all}, {name: "teams.any", var: teams_any}, {name: "followers.not", var: followers_not}, {name: "created_by.any", var: created_by_any}, {name: "created_by.not", var: created_by_not}, {name: "assigned_by.any", var: assigned_by_any}, {name: "assigned_by.not", var: assigned_by_not}, {name: "liked_by.not", var: liked_by_not}, {name: "commented_on_by.not", var: commented_on_by_not}, {name: "due_on.before", var: due_on_before}, {name: "due_on.after", var: due_on_after}, {name: due_on, var: due_on}, {name: "due_at.before", var: due_at_before}, {name: "due_at.after", var: due_at_after}, {name: "start_on.before", var: start_on_before}, {name: "start_on.after", var: start_on_after}, {name: start_on, var: start_on}, {name: "created_on.before", var: created_on_before}, {name: "created_on.after", var: created_on_after}, {name: created_on, var: created_on}, {name: "created_at.before", var: created_at_before}, {name: "created_at.after", var: created_at_after}, {name: "completed_on.before", var: completed_on_before}, {name: "completed_on.after", var: completed_on_after}, {name: completed_on, var: completed_on}, {name: "completed_at.before", var: completed_at_before}, {name: "completed_at.after", var: completed_at_after}, {name: "modified_on.before", var: modified_on_before}, {name: "modified_on.after", var: modified_on_after}, {name: modified_on, var: modified_on}, {name: "modified_at.before", var: modified_at_before}, {name: "modified_at.after", var: modified_at_after}, {name: is_blocking, var: is_blocking}, {name: is_blocked, var: is_blocked}, {name: has_attachment, var: has_attachment}, {name: completed, var: completed}, {name: is_subtask, var: is_subtask}, {name: sort_by, var: sort_by}, {name: sort_ascending, var: sort_ascending}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, text: $text, resource_subtype: $resource_subtype, assignee_any: $assignee_any, assignee_not: $assignee_not, portfolios_any: $portfolios_any, projects_any: $projects_any, projects_not: $projects_not, projects_all: $projects_all, sections_any: $sections_any, sections_not: $sections_not, sections_all: $sections_all, tags_any: $tags_any, tags_not: $tags_not, tags_all: $tags_all, teams_any: $teams_any, followers_not: $followers_not, created_by_any: $created_by_any, created_by_not: $created_by_not, assigned_by_any: $assigned_by_any, assigned_by_not: $assigned_by_not, liked_by_not: $liked_by_not, commented_on_by_not: $commented_on_by_not, due_on_before: $due_on_before, due_on_after: $due_on_after, due_on: $due_on, due_at_before: $due_at_before, due_at_after: $due_at_after, start_on_before: $start_on_before, start_on_after: $start_on_after, start_on: $start_on, created_on_before: $created_on_before, created_on_after: $created_on_after, created_on: $created_on, created_at_before: $created_at_before, created_at_after: $created_at_after, completed_on_before: $completed_on_before, completed_on_after: $completed_on_after, completed_on: $completed_on, completed_at_before: $completed_at_before, completed_at_after: $completed_at_after, modified_on_before: $modified_on_before, modified_on_after: $modified_on_after, modified_on: $modified_on, modified_at_before: $modified_at_before, modified_at_after: $modified_at_after, is_blocking: $is_blocking, is_blocked: $is_blocked, has_attachment: $has_attachment, completed: $completed, is_subtask: $is_subtask, sort_by: $sort_by, sort_ascending: $sort_ascending
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get teams in a workspace
#
# GET /workspaces/{workspace_gid}/teams
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getTeamsForWorkspace
export def "get-teams-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/teams"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get objects via typeahead
#
# GET /workspaces/{workspace_gid}/typeahead
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: typeaheadForWorkspace
export def "typeahead-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string@resource-type-completer-1 # The type of values the typeahead should return. You can choose from one of the following: `custom_field`, `project`, `project_template`, `portfolio`, `tag`, `task`, and `user`. Note that unlike in the names of endpoints, the types listed here are in singular form (e.g. `task`). Using multiple types is not yet supported. (required, default: user)
  --type: string@type-completer # *Deprecated: new integrations should prefer the resource_type field.* (default: user)
  --query: string # The string that will be used to search for relevant objects. If an empty string is passed in, the API will return results. (e.g. Greg)
  --count: int # The number of results to return. The default is 20 if this parameter is omitted, with a minimum of 1 and a maximum of 100. If there are fewer results found than requested, all will be returned. (e.g. 20)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/typeahead"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: resource_type, var: resource_type, required: true, default: user}, {name: type, var: type}, {name: query, var: query}, {name: count, var: count}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, resource_type: $resource_type, type: $type, query: $query, count: $count, opt_pretty: $opt_pretty, opt_fields: $opt_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get users in a workspace or organization
#
# GET /workspaces/{workspace_gid}/users
# Returns: record<data: table<gid: string, resource_type: string, name: string>>
# operationId: getUsersForWorkspace
export def "get-users-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/users"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, opt_pretty: $opt_pretty, opt_fields: $opt_fields, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the workspace memberships for a workspace
#
# GET /workspaces/{workspace_gid}/workspace_memberships
# Returns: record<data: table<gid: string, resource_type: string, user: record, workspace: record>>
# operationId: getWorkspaceMembershipsForWorkspace
export def "get-workspace-memberships-for-workspace" [
  workspace_gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # A string identifying a user. This can either be the string "me", an email, or the gid of a user. (e.g. me)
  --opt-pretty: oneof<nothing, bool> # Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging. (e.g. true, allows empty value)
  --opt-fields: list<string> # Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options. (e.g. [followers, assignee])
  --limit: int # Results per page. The number of objects to return per page. The value must be between 1 and 100. (e.g. 50)
  --offset: string # Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.' (e.g. eyJ0eXAiOJiKV1iQLCJhbGciOiJIUzI1NiJ9)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/workspaces/{workspace_gid}/workspace_memberships"
    path_params: [{name: workspace_gid, var: workspace_gid}]
    query: [{name: user, var: user}, {name: opt_pretty, var: opt_pretty}, {name: opt_fields, var: opt_fields, style: csv}, {name: limit, var: limit}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    workspace_gid: $workspace_gid, user: $user, opt_pretty: $opt_pretty, opt_fields: $opt_fields, limit: $limit, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
