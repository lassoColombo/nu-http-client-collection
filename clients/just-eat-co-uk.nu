# Auto-generated client for Just Eat UK v1.0.0
# Source: https://api.apis.guru/v2/specs/just-eat.co.uk/1.0.0/openapi.json
# Auth: --token flag or $env.JUST_EAT_UK_TOKEN

const CLIENT = {
  base_url: "https://uk.api.just-eat.io"
  token_env_var: "JUST_EAT_UK_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: bearer, in: header, header_name: Authorization, prefix: Bearer}
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

def base-url-completer [] { ["https://uk.api.just-eat.io" "https://i18n.api.just-eat.io" "https://aus.api.just-eat.io"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def tenant-completer [] { ["au" "dk" "es" "ie" "it" "no" "nz" "uk"] }
def account-type-completer [] { ["registered"] }
def registration-source-completer [] { ["Guest" "Native"] }
def type-completer [] { ["marketing"] }
def channel-completer [] { ["email" "push" "sms"] }
def event-completer [] { ["AtDeliveryAddress" "Delivered" "DriverAssigned" "DriverAtRestaurant" "OnItsWay"] }
def result-completer [] { ["fail" "success"] }
def reason-completer [] { ["cust_cancelled_changed_mind" "cust_cancelled_delivery_too_long" "cust_cancelled_made_mistake" "cust_cancelled_other" "delivery_partner_cancelled" "rest_cancelled_customer_absent" "rest_cancelled_customer_requested" "rest_cancelled_declined" "rest_cancelled_drivers_unavailable" "rest_cancelled_fake_order" "rest_cancelled_other" "rest_cancelled_out_of_stock" "rest_cancelled_too_busy" "system_cancelled_other" "system_cancelled_test_order"] }
def event-completer-1 [] { ["Ready for pickup"] }
def day-of-week-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday"] }
def service-type-completer [] { ["Collection" "Delivery"] }
def late-order-status-completer [] { ["Delivered" "OnItsWay" "Preparing"] }
def rejected-reason-code-completer [] { ["BadTraffic" "BadWeather" "BusierThanExpected" "CompensatedWithItem" "NoReason"] }
def reason-code-completer [] { ["BeingPrepared" "Delivered" "NotSet" "OnItsWay" "Unknown"] }
def decision-completer [] { ["Accepted" "PartiallyAccepted" "Rejected"] }
def reason-completer-1 [] { ["AddExtraItem" "AlreadyRefunded" "FoodWasIntact" "ItemReplaced" "OrderWasHot" "OrderWasOnTime" "OrderWasPacked" "Other" "PartialRefundRequired" "WasNotMissing" "WillRedeliver"] }
def legacy-temp-offline-type-completer [] { ["ClosedDueToEvent" "ClosedToday" "FailedJctConnection" "IgnoredOrders" "NoTrOverride" "None" "TempOffline" "Unset"] }
def x-je-user-role-completer [] { ["Operations" "Restaurant" "System"] }
def reason-code-completer-1 [] { ["no_answer" "problem_with_address"] }
def status-completer [] { ["driver_at_address" "repreparing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-checkout-tenant-checkout-id: "record<customer: record<firstName: string, lastName: string, phoneNumber: string>, fulfilment: record<location: record<address: record, geolocation: record>, time: record<asap: bool, scheduled: record>>, isFulfillable: bool, issues: table<code: string>, restaurant: record<availabilityId: string, id: string>, serviceType: string>"
    patch-checkout-tenant-checkout-id: "record<isFulfillable: bool, issues: table<code: string>>"
    get-checkout-tenant-checkout-id-fulfilment-availabletimes: "record<asapAvailable: bool, times: table<from: string, to: string>>"
    get-consumers-tenant: "int"
    post-consumers-tenant: "record<token: string, type: string>"
    get-consumers-tenant-me-communication-preferences: "record<marketing: record<isDefault: bool, subscribedChannels: list<string>>>"
    get-consumers-tenant-me-communication-preferences-type: "record<isDefault: bool, subscribedChannels: list<string>>"
    get-delivery-fees-tenant: "record<restaurants: table<bands: list, minimumOrderValue: float, restaurantId: string>>"
    get-delivery-estimate: "record<DurationInMinutes: string, RestaurantReference: string>"
    get-delivery-pools: "record<delivery-pool-id: record<name: string, restaurants: list<float>>>"
    get-delivery-pools-delivery-pool-id: "record<name: string, restaurants: list<float>>"
    patch-delivery-pools-delivery-pool-id: "record<name: string, restaurants: list<float>>"
    put-delivery-pools-delivery-pool-id: "record<name: string, restaurants: list<float>>"
    get-delivery-pools-delivery-pool-id-availability-relative: "record<bestGuess: string>"
    put-delivery-pools-delivery-pool-id-restaurants: "record<restaurants: list<float>>"
    post-orders: "record<OrderId: string>"
    put-restaurants-driver-eta: "record<ignoredRestaurantIds: list<string>>"
    get-restaurants-tenant-restaurant-id-catalogue: "record<currency: string, description: string, name: string, restaurantId: string>"
    get-restaurants-tenant-restaurant-id-catalogue-availabilities: "record<paging: record<cursors: record<after: string>>, availabilities: table<description: string, id: string, name: string, serviceTypes: list, times: list>>"
    get-restaurants-tenant-restaurant-id-catalogue-categories: "record<paging: record<cursors: record<after: string>>, categories: table<description: string, id: string, name: string>>"
    get-restaurants-tenant-restaurant-id-catalogue-categories-category-id-items: "record<paging: record<cursors: record<after: string>>, itemIds: list<string>>"
    get-restaurants-tenant-restaurant-id-catalogue-items: "record<paging: record<cursors: record<after: string>>, items: table<description: string, id: string, labels: list, name: string, requireOtherProducts: bool, type: string>>"
    get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups: "record<paging: record<cursors: record<after: string>>, dealGroups: table<id: string, name: string, numberOfChoices: int>>"
    get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups-deal-group-id-dealitemvariations: "record<paging: record<cursors: record<after: string>>, dealItemVariations: table<additionPrice: float, dealItemVariationId: string, maxChoices: int, minChoices: int>>"
    get-restaurants-tenant-restaurant-id-catalogue-items-item-id-modifiergroups: "record<paging: record<cursors: record<after: string>>, modifierGroups: table<id: string, maxChoices: int, minChoices: int, modifiers: list, name: string>>"
    get-restaurants-tenant-restaurant-id-catalogue-items-item-id-variations: "record<paging: record<cursors: record<after: string>>, variations: table<availabilityIds: list, basePrice: float, dealGroupsIds: list, dealOnly: bool, id: string, kitchenNumber: string, modifierGroupsIds: list, name: string, type: string>>"
    get-restaurants-tenant-restaurant-id-customerclaims: "record<claims: table<affectedItems: list, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record, restaurantResponse: record, state: string, submittedDate: string, totalClaimed: float>>"
    get-restaurants-tenant-restaurant-id-customerclaims-id: "record<affectedItems: table<additionalContext: string, decision: string, id: string, name: string, quantity: float, totalClaimed: float, unitPrice: float>, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record<decision: string, resolvedChannel: string, resolvedDate: string, totalClaimedAccepted: float>, restaurantResponse: record<decision: string, items: list<record>, justification: record<comments: string, reason: string>>, state: string, submittedDate: string, totalClaimed: float>"
    get-restaurants-tenant-restaurant-id-fees: "record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>>"
    put-restaurants-tenant-restaurant-id-fees: "record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>>"
    put-menu-for-ingestion: "record<correlationId: string>"
    get-order-times: "table<dayOfWeek: string, lowerBoundMinutes: int, serviceType: string, upperBoundMinutes: int>"
    get-restaurant-service-times: "record<serviceTimes: record<friday: record<collection: list, delivery: list>, monday: record<collection: list, delivery: list>, saturday: record<collection: list, delivery: list>, sunday: record<collection: list, delivery: list>, thursday: record<collection: list, delivery: list>, tuesday: record<collection: list, delivery: list>, wednesday: record<collection: list, delivery: list>>>"
    put-restaurant-service-times: "record<serviceTimes: record<friday: record<collection: list, delivery: list>, monday: record<collection: list, delivery: list>, saturday: record<collection: list, delivery: list>, sunday: record<collection: list, delivery: list>, thursday: record<collection: list, delivery: list>, tuesday: record<collection: list, delivery: list>, wednesday: record<collection: list, delivery: list>>>"
    get-search-autocomplete-tenant: "record<terms: table<classification: string, term: string>>"
    get-search-restaurants-tenant: "record<restaurants: table<isSponsored: bool, products: list, restaurantId: string>>"
    post-v1-tenant-restaurants-event-offline: "record<restaurantEventId: string, restaurantIds: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-acceptance-requested" "put-attempted-delivery-query-resolved" "get-checkout-tenant-checkout-id" "patch-checkout-tenant-checkout-id" "get-checkout-tenant-checkout-id-fulfilment-availabletimes" "get-consumers-tenant" "post-consumers-tenant" "get-consumers-tenant-me-communication-preferences" "get-consumers-tenant-me-communication-preferences-type" "put-consumers-tenant-me-communication-preferences-type" "delete-consumers-tenant-me-communication-preferences-type-subscribed-channels-channel" "post-consumers-tenant-me-communication-preferences-type-subscribed-channels-channel" "put-delivery-failed" "get-delivery-fees-tenant" "get-delivery-estimate" "get-delivery-pools" "post-delivery-pools" "delete-delivery-pools-delivery-pool-id" "get-delivery-pools-delivery-pool-id" "patch-delivery-pools-delivery-pool-id" "put-delivery-pools-delivery-pool-id" "get-delivery-pools-delivery-pool-id-availability-relative" "put-delivery-pools-delivery-pool-id-availability-relative" "put-delivery-pools-delivery-pool-id-hours" "delete-delivery-pools-delivery-pool-id-restaurants" "put-delivery-pools-delivery-pool-id-restaurants" "put-driver-assigned-to-delivery" "put-driver-at-delivery-address" "put-driver-at-restaurant" "put-driver-has-delivered-order" "put-driver-location" "put-driver-on-their-way-to-delivery-address" "post-late-order-compensation-query" "post-late-order-query" "post-menu-ingestion-complete" "post-order-accepted" "post-order-cancelled" "post-order-eligible-for-restaurant-compensation" "put-order-is-ready-for-pickup" "post-order-ready-for-preparation-async" "post-order-ready-for-preparation-sync" "post-order-rejected" "put-order-requires-delivery-acceptance" "post-order-time-updated" "post-orders" "put-orders-deliverystate-driverlocation" "put-orders-order-id-accept" "put-orders-order-id-cancel" "post-orders-order-id-complete" "put-orders-order-id-deliverystate-atdeliveryaddress" "put-orders-order-id-deliverystate-atrestaurant" "put-orders-order-id-deliverystate-atrestauranteta" "put-orders-order-id-deliverystate-delivered" "put-orders-order-id-deliverystate-driverassigned" "put-orders-order-id-deliverystate-driverlocation" "put-orders-order-id-deliverystate-driverunassigned" "put-orders-order-id-deliverystate-onitsway" "put-orders-order-id-duedate" "put-orders-order-id-ignore" "post-orders-order-id-readyforcollection" "put-orders-order-id-reject" "post-orders-tenant-order-id-consumerqueries-lateorder-restaurantresponse" "post-orders-tenant-order-id-consumerqueries-lateordercompensation-restaurantresponse" "post-orders-tenant-order-id-restaurantqueries-compensation" "put-redelivery-requested" "put-restaurant-offline-status" "put-restaurant-online-status" "search-by-location" "search-by-postcode" "put-restaurants-driver-eta" "get-restaurants-tenant-restaurant-id-catalogue" "get-restaurants-tenant-restaurant-id-catalogue-availabilities" "get-restaurants-tenant-restaurant-id-catalogue-categories" "get-restaurants-tenant-restaurant-id-catalogue-categories-category-id-items" "get-restaurants-tenant-restaurant-id-catalogue-items" "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups" "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups-deal-group-id-dealitemvariations" "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-modifiergroups" "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-variations" "get-restaurants-tenant-restaurant-id-customerclaims" "get-restaurants-tenant-restaurant-id-customerclaims-id" "post-restaurants-tenant-restaurant-id-customerclaims-id-restaurantresponse" "put-restaurants-tenant-restaurant-id-customerclaims-id-restaurantresponse-justification" "get-restaurants-tenant-restaurant-id-fees" "put-restaurants-tenant-restaurant-id-fees" "get-restaurants-tenant-restaurant-id-menu" "put-menu-for-ingestion" "get-order-times" "update-order-time" "get-restaurant-service-times" "put-restaurant-service-times" "get-search-autocomplete-tenant" "get-search-restaurants-tenant" "post-send-to-pos-failed" "post-v1-tenant-restaurants-event-offline" "delete-v1-tenant-restaurants-id-event-offline" "post-tenant-orders-order-id-queries-attempteddelivery" "post-tenant-orders-order-id-queries-attempteddelivery-resolution-redeliverorder" "commands"] | sort) } | get name | first)
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

# Acceptance requested
#
# POST /acceptance-requested
export def "post-acceptance-requested" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: float, Name?: string, PreviousRestaurantOrderCount?: float, PreviousTotalOrderCount?: float}
  --customer-notes: record
  --friendly-order-reference: string
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneMaskingCode?: string, PhoneNumber?: string, PreparationTime?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: float, Reference?: string, TotalPrice?: float, UnitPrice?: float}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string, TimeZone?: string}
  --restrictions: list # This is a list of types of restricted items contained in the order. — item shape: {Type?: "Alcohol"}
  --total-price: float # format: money
]: any -> any {
  $in | http-request {
    method: post
    path: "/acceptance-requested"
    body: {content_type: "application/json", kind: json, fields: [{name: Currency, var: currency}, {name: Customer, var: customer}, {name: CustomerNotes, var: customer_notes}, {name: FriendlyOrderReference, var: friendly_order_reference}, {name: Fulfilment, var: fulfilment}, {name: IsTest, var: is_test}, {name: Items, var: items}, {name: OrderId, var: order_id}, {name: Payment, var: payment}, {name: PlacedDate, var: placed_date}, {name: PriceBreakdown, var: price_breakdown}, {name: Restaurant, var: restaurant}, {name: Restrictions, var: restrictions}, {name: TotalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    currency: $currency, customer: $customer, customer_notes: $customer_notes, friendly_order_reference: $friendly_order_reference, fulfilment: $fulfilment, is_test: $is_test, items: $items, order_id: $order_id, payment: $payment, placed_date: $placed_date, price_breakdown: $price_breakdown, restaurant: $restaurant, restrictions: $restrictions, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Attempted delivery query resolved
#
# PUT /attempted-delivery-query-resolved
export def "put-attempted-delivery-query-resolved" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The ID of the order for which an attempted delivery query has been resolved
  --resolution: record # Details of the resolution to the query — shape: {Cancellation?: record, Redelivery?: record, Type?: "order_cancelled"|"redeliver_order"}
  --tenant: string@tenant-completer # The tenant of the restaurant the order was placed at
]: any -> any {
  $in | http-request {
    method: put
    path: "/attempted-delivery-query-resolved"
    body: {content_type: "application/json", kind: json, fields: [{name: OrderId, var: order_id}, {name: Resolution, var: resolution}, {name: Tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, resolution: $resolution, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Checkout
#
# GET /checkout/{tenant}/{checkoutId}
# Returns: record<customer: record<firstName: string, lastName: string, phoneNumber: string>, fulfilment: record<location: record<address: record, geolocation: record>, time: record<asap: bool, scheduled: record>>, isFulfillable: bool, issues: table<code: string>, restaurant: record<availabilityId: string, id: string>, serviceType: string>
export def "get-checkout-tenant-checkout-id" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checkout/{tenant}/{checkoutId}"
    path_params: [{name: tenant, var: tenant}, {name: checkoutId, var: checkout_id}]
    header: [{name: User-Agent, var: user_agent, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, checkout_id: $checkout_id, user_agent: $user_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update Checkout
#
# PATCH /checkout/{tenant}/{checkoutId}
# Returns: record<isFulfillable: bool, issues: table<code: string>>
export def "patch-checkout-tenant-checkout-id" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request. (required)
  --customer: record # Details of the customer making the purchase. (nullable) — shape: {dateOfBirth?: string, firstName?: string, lastName?: string, phoneNumber?: string}
  --fulfilment: record # How and when the items will be received by the customer. (nullable) — shape: {location?: record, time?: record}
  --notes: list # Instructions about the order that the customer wants to submit. (nullable) — item shape: {note: string, type: "delivery"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/checkout/{tenant}/{checkoutId}"
    path_params: [{name: tenant, var: tenant}, {name: checkoutId, var: checkout_id}]
    header: [{name: User-Agent, var: user_agent, required: true}]
    body: {content_type: "application/json-patch+json", kind: json, fields: [{name: customer, var: customer}, {name: fulfilment, var: fulfilment}, {name: notes, var: notes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, checkout_id: $checkout_id, user_agent: $user_agent, customer: $customer, fulfilment: $fulfilment, notes: $notes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Available Fulfilment Times
#
# GET /checkout/{tenant}/{checkoutId}/fulfilment/availabletimes
# Returns: record<asapAvailable: bool, times: table<from: string, to: string>>
export def "get-checkout-tenant-checkout-id-fulfilment-availabletimes" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request. (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/checkout/{tenant}/{checkoutId}/fulfilment/availabletimes"
    path_params: [{name: tenant, var: tenant}, {name: checkoutId, var: checkout_id}]
    header: [{name: User-Agent, var: user_agent, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, checkout_id: $checkout_id, user_agent: $user_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get consumers details
#
# GET /consumers/{tenant}
# Returns: int
export def "get-consumers-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: string # Email address of the consumer. (required)
  --account-type: string@account-type-completer # The account type of the consumer - currently only 'registered' accounts are supported. (required, default: registered)
  --count: string # Returns the number of consumers that matches the `emailAddress` and `accountType`. The query value should be empty, e.g. `/consumers/uk/?emailAddress=someone@email.com&accountType=registered&count`. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/consumers/{tenant}"
    path_params: [{name: tenant, var: tenant}]
    query: [{name: emailAddress, var: email_address, required: true}, {name: accountType, var: account_type, required: true, default: registered}, {name: count, var: count, required: true}]
    accept: ["text/plain"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, email_address: $email_address, account_type: $account_type, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create consumer
#
# POST /consumers/{tenant}
# Returns: record<token: string, type: string>
export def "post-consumers-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The consumer's email address (format: email)
  first_name: string # The consumer's first name
  last_name: string # The consumer's last name
  --marketing-preferences: list # item shape: {channelName?: "Email"|"Push"|"Sms", dateUpdated?: string, isSubscribed?: bool}
  --password: string # The consumer's password
  --registration-source: string@registration-source-completer # The registration source of the consumer. Australia and New Zealand only support Guest (default: Native)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/consumers/{tenant}"
    path_params: [{name: tenant, var: tenant}]
    body: {content_type: "application/json", kind: json, fields: [{name: emailAddress, var: email_address}, {name: firstName, var: first_name}, {name: lastName, var: last_name}, {name: marketingPreferences, var: marketing_preferences}, {name: password, var: password}, {name: registrationSource, var: registration_source}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tenant: $tenant, email_address: $email_address, first_name: $first_name, last_name: $last_name, marketing_preferences: $marketing_preferences, password: $password, registration_source: $registration_source
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get communication preferences
#
# GET /consumers/{tenant}/me/communication-preferences
# Returns: record<marketing: record<isDefault: bool, subscribedChannels: list<string>>>
export def "get-consumers-tenant-me-communication-preferences" [
  tenant: string
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
    path: "/consumers/{tenant}/me/communication-preferences"
    path_params: [{name: tenant, var: tenant}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get channel subscriptions for a given consumer's communication preference type
#
# GET /consumers/{tenant}/me/communication-preferences/{type}
# Returns: record<isDefault: bool, subscribedChannels: list<string>>
export def "get-consumers-tenant-me-communication-preferences-type" [
  tenant: string
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/consumers/{tenant}/me/communication-preferences/{type}"
    path_params: [{name: tenant, var: tenant}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set only the channel subscriptions for a given consumer's communication preference type
#
# PUT /consumers/{tenant}/me/communication-preferences/{type}
export def "put-consumers-tenant-me-communication-preferences-type" [
  tenant: string
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
  --subscribed-channels: list<string> # The list of channels that the consumer should only be subscribed to.
]: any -> any {
  $in | http-request {
    method: put
    path: "/consumers/{tenant}/me/communication-preferences/{type}"
    path_params: [{name: tenant, var: tenant}, {name: type, var: type}]
    body: {content_type: "application/json", kind: json, fields: [{name: subscribedChannels, var: subscribed_channels}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tenant: $tenant, type: $type, subscribed_channels: $subscribed_channels
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove subscription of a specific communication preference channel
#
# DELETE /consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}
export def "delete-consumers-tenant-me-communication-preferences-type-subscribed-channels-channel" [
  tenant: string
  type: string@type-completer
  channel: string
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
]: any -> any {
  $in | http-request {
    method: delete
    path: "/consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}"
    path_params: [{name: tenant, var: tenant}, {name: type, var: type}, {name: channel, var: channel}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tenant: $tenant, type: $type, channel: $channel, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to a specific communication preference channel
#
# POST /consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}
export def "post-consumers-tenant-me-communication-preferences-type-subscribed-channels-channel" [
  tenant: string
  type: string@type-completer
  channel: string@channel-completer
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
]: any -> any {
  $in | http-request {
    method: post
    path: "/consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}"
    path_params: [{name: tenant, var: tenant}, {name: type, var: type}, {name: channel, var: channel}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tenant: $tenant, type: $type, channel: $channel, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delivery Attempt Failed
#
# PUT /delivery-failed
export def "put-delivery-failed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The id of the order
  --reason: string # The reason for creating the attempted delivery
  --restaurant-id: float # The id of the restaurant
  --tenant: string # The tenant associated with the order
]: any -> any {
  $in | http-request {
    method: put
    path: "/delivery-failed"
    body: {content_type: "application/json", kind: json, fields: [{name: OrderId, var: order_id}, {name: Reason, var: reason}, {name: RestaurantId, var: restaurant_id}, {name: Tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, reason: $reason, restaurant_id: $restaurant_id, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get restaurant delivery fees
#
# GET /delivery-fees/{tenant}
# Returns: record<restaurants: table<bands: list, minimumOrderValue: float, restaurantId: string>>
export def "get-delivery-fees-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurant-ids: list<string> # Restaurant IDs which fees are requested for. e.g. `?restaurantIds=1,2,3,4` (required, e.g. [1, 2, 3, 4])
  --delivery-time: string # Delivery date/time when fees are required (ISO8601 format). (required, format: date-time, e.g. 2019-09-05T12:43:48.431Z)
  --zone: string # Postcode or other location name identifying the location to which delivery is required. For use when precise location is not available. This will be removed in future in favour of location. (e.g. BS1)
  --latlong: list<float> # Point to which delivery is required (latitude, longitude). Supply this where possible as support for zone-only based lookups will be removed in future. (e.g. [51.3851513, -2.0841275])
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/delivery-fees/{tenant}"
    path_params: [{name: tenant, var: tenant}]
    query: [{name: restaurantIds, var: restaurant_ids, style: csv, required: true}, {name: deliveryTime, var: delivery_time, required: true}, {name: zone, var: zone}, {name: latlong, var: latlong, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_ids: $restaurant_ids, delivery_time: $delivery_time, zone: $zone, latlong: $latlong
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get delivery estimate
#
# GET /delivery/estimate
# DEPRECATED
# Returns: record<DurationInMinutes: string, RestaurantReference: string>
@deprecated
export def "get-delivery-estimate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurant-reference: string # The reference of the restaurant to estimate the delivery time from. (required)
  --to-lat: string # The latitude of the position to estimate the delivery time to.
  --to-lon: string # The longitude of the position to estimate the delivery time to.
  --to-postcode: string # The postcode to estimate the delivery time to.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/delivery/estimate"
    query: [{name: restaurantReference, var: restaurant_reference, required: true}, {name: toLat, var: to_lat}, {name: toLon, var: to_lon}, {name: toPostcode, var: to_postcode}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    restaurant_reference: $restaurant_reference, to_lat: $to_lat, to_lon: $to_lon, to_postcode: $to_postcode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get your delivery pools
#
# GET /delivery/pools
# Returns: record<delivery-pool-id: record<name: string, restaurants: list<float>>>
export def "get-delivery-pools" [
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
    path: "/delivery/pools"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new delivery pool
#
# POST /delivery/pools
export def "post-delivery-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  $in | http-request {
    method: post
    path: "/delivery/pools"
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: restaurants, var: restaurants}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    name: $name, restaurants: $restaurants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}
export def "delete-delivery-pools-delivery-pool-id" [
  delivery_pool_id: string
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
    path: "/delivery/pools/{deliveryPoolId}"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an individual delivery pool
#
# GET /delivery/pools/{deliveryPoolId}
# Returns: record<name: string, restaurants: list<float>>
export def "get-delivery-pools-delivery-pool-id" [
  delivery_pool_id: string
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
    path: "/delivery/pools/{deliveryPoolId}"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify a delivery pool
#
# PATCH /delivery/pools/{deliveryPoolId}
# Returns: record<name: string, restaurants: list<float>>
export def "patch-delivery-pools-delivery-pool-id" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/delivery/pools/{deliveryPoolId}"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: restaurants, var: restaurants}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id, name: $name, restaurants: $restaurants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Replace an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}
# Returns: record<name: string, restaurants: list<float>>
export def "put-delivery-pools-delivery-pool-id" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/delivery/pools/{deliveryPoolId}"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: restaurants, var: restaurants}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id, name: $name, restaurants: $restaurants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get availability for pickup
#
# GET /delivery/pools/{deliveryPoolId}/availability/relative
# Returns: record<bestGuess: string>
export def "get-delivery-pools-delivery-pool-id-availability-relative" [
  delivery_pool_id: string
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
    path: "/delivery/pools/{deliveryPoolId}/availability/relative"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set availability for pickup
#
# PUT /delivery/pools/{deliveryPoolId}/availability/relative
export def "put-delivery-pools-delivery-pool-id-availability-relative" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-guess: string # Your best estimation (hh:mm:ss)
]: any -> any {
  $in | http-request {
    method: put
    path: "/delivery/pools/{deliveryPoolId}/availability/relative"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bestGuess, var: best_guess}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id, best_guess: $best_guess
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set the delivery pools daily start and end times
#
# PUT /delivery/pools/{deliveryPoolId}/hours
export def "put-delivery-pools-delivery-pool-id-hours" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  friday: record # shape: {closed?: bool, poolTimes: list}
  monday: record # shape: {closed?: bool, poolTimes: list}
  saturday: record # shape: {closed?: bool, poolTimes: list}
  sunday: record # shape: {closed?: bool, poolTimes: list}
  thursday: record # shape: {closed?: bool, poolTimes: list}
  tuesday: record # shape: {closed?: bool, poolTimes: list}
  wednesday: record # shape: {closed?: bool, poolTimes: list}
]: any -> any {
  $in | http-request {
    method: put
    path: "/delivery/pools/{deliveryPoolId}/hours"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: friday, var: friday}, {name: monday, var: monday}, {name: saturday, var: saturday}, {name: sunday, var: sunday}, {name: thursday, var: thursday}, {name: tuesday, var: tuesday}, {name: wednesday, var: wednesday}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id, friday: $friday, monday: $monday, saturday: $saturday, sunday: $sunday, thursday: $thursday, tuesday: $tuesday, wednesday: $wednesday
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove restaurants from a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}/restaurants
export def "delete-delivery-pools-delivery-pool-id-restaurants" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  $in | http-request {
    method: delete
    path: "/delivery/pools/{deliveryPoolId}/restaurants"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: restaurants, var: restaurants}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id, restaurants: $restaurants
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add restaurants to an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}/restaurants
# Returns: record<restaurants: list<float>>
export def "put-delivery-pools-delivery-pool-id-restaurants" [
  delivery_pool_id: string
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
    path: "/delivery/pools/{deliveryPoolId}/restaurants"
    path_params: [{name: deliveryPoolId, var: delivery_pool_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    delivery_pool_id: $delivery_pool_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver Assigned to Delivery
#
# PUT /driver-assigned-to-delivery
export def "put-driver-assigned-to-delivery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-assigned-to-delivery"
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EstimatedDeliveryTime, var: estimated_delivery_time}, {name: EstimatedPickupTime, var: estimated_pickup_time}, {name: Event, var: event}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_contact_number: $driver_contact_number, driver_name: $driver_name, estimated_delivery_time: $estimated_delivery_time, estimated_pickup_time: $estimated_pickup_time, event: $event, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver at delivery address
#
# PUT /driver-at-delivery-address
export def "put-driver-at-delivery-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-at-delivery-address"
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EstimatedDeliveryTime, var: estimated_delivery_time}, {name: EstimatedPickupTime, var: estimated_pickup_time}, {name: Event, var: event}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_contact_number: $driver_contact_number, driver_name: $driver_name, estimated_delivery_time: $estimated_delivery_time, estimated_pickup_time: $estimated_pickup_time, event: $event, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver at restaurant
#
# PUT /driver-at-restaurant
export def "put-driver-at-restaurant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-at-restaurant"
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EstimatedDeliveryTime, var: estimated_delivery_time}, {name: EstimatedPickupTime, var: estimated_pickup_time}, {name: Event, var: event}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_contact_number: $driver_contact_number, driver_name: $driver_name, estimated_delivery_time: $estimated_delivery_time, estimated_pickup_time: $estimated_pickup_time, event: $event, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver has delivered order
#
# PUT /driver-has-delivered-order
export def "put-driver-has-delivered-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-has-delivered-order"
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EstimatedDeliveryTime, var: estimated_delivery_time}, {name: EstimatedPickupTime, var: estimated_pickup_time}, {name: Event, var: event}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_contact_number: $driver_contact_number, driver_name: $driver_name, estimated_delivery_time: $estimated_delivery_time, estimated_pickup_time: $estimated_pickup_time, event: $event, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver Location
#
# PUT /driver-location
export def "put-driver-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # e.g. {Latitude: 51.51641, Longitude: -0.103198} — shape: {Latitude: float, Longitude: float}
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-location"
    body: {content_type: "application/json", kind: json, fields: [{name: Location, var: location}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    location: $location, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Driver on their way to delivery address
#
# PUT /driver-on-their-way-to-delivery-address
export def "put-driver-on-their-way-to-delivery-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/driver-on-their-way-to-delivery-address"
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EstimatedDeliveryTime, var: estimated_delivery_time}, {name: EstimatedPickupTime, var: estimated_pickup_time}, {name: Event, var: event}, {name: OrderId, var: order_id}, {name: TimeStamp, var: time_stamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    driver_contact_number: $driver_contact_number, driver_name: $driver_name, estimated_delivery_time: $estimated_delivery_time, estimated_pickup_time: $estimated_pickup_time, event: $event, order_id: $order_id, time_stamp: $time_stamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# late order compensation query, restaurant response required
#
# POST /late-order-compensation-query
export def "post-late-order-compensation-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --compensation-options: list # item shape: {amount?: float, isRecommended?: bool}
  --order-id: string # Just Eat order identifier
  --restaurant-id: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  $in | http-request {
    method: post
    path: "/late-order-compensation-query"
    body: {content_type: "application/json", kind: json, fields: [{name: compensationOptions, var: compensation_options}, {name: orderId, var: order_id}, {name: restaurantId, var: restaurant_id}, {name: tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    compensation_options: $compensation_options, order_id: $order_id, restaurant_id: $restaurant_id, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# late order query, restaurant response required
#
# POST /late-order-query
export def "post-late-order-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Just Eat order identifier
  --restaurant-id: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  $in | http-request {
    method: post
    path: "/late-order-query"
    body: {content_type: "application/json", kind: json, fields: [{name: orderId, var: order_id}, {name: restaurantId, var: restaurant_id}, {name: tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, restaurant_id: $restaurant_id, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Menu ingestion complete
#
# POST /menu-ingestion-complete
export def "post-menu-ingestion-complete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --correlation-id: string # The ID of the execution which has been completed
  --fault: record # Details of the fault which caused the menu ingestion to fail. This is only present if menu ingestion did not complete successfully — shape: {errors?: list, id?: string}
  --restaurant-id: string # The Just Eat restaurant ID
  --result: string@result-completer # The result of the menu ingestion process (format: enum)
  --tenant: string@tenant-completer # Country code for the market the restaurant is in (format: enum)
  --timestamp: string # The ISO-8601 datetime at which the menu ingestion completed (format: date-time)
]: any -> any {
  $in | http-request {
    method: post
    path: "/menu-ingestion-complete"
    body: {content_type: "application/json", kind: json, fields: [{name: correlationId, var: correlation_id}, {name: fault, var: fault}, {name: restaurantId, var: restaurant_id}, {name: result, var: result}, {name: tenant, var: tenant}, {name: timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    correlation_id: $correlation_id, fault: $fault, restaurant_id: $restaurant_id, result: $result, tenant: $tenant, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order accepted
#
# POST /order-accepted
export def "post-order-accepted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-for: string # format: date-time
  --event: string
  --order-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-accepted"
    body: {content_type: "application/json", kind: json, fields: [{name: AcceptedFor, var: accepted_for}, {name: Event, var: event}, {name: OrderId, var: order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    accepted_for: $accepted_for, event: $event, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order cancelled
#
# POST /order-cancelled
export def "post-order-cancelled" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string
  --order-id: string
  --reason: string@reason-completer # The reason the order was cancelled.
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-cancelled"
    body: {content_type: "application/json", kind: json, fields: [{name: Event, var: event}, {name: OrderId, var: order_id}, {name: Reason, var: reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event: $event, order_id: $order_id, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order Eligible For Restaurant Compensation
#
# POST /order-eligible-for-restaurant-compensation
export def "post-order-eligible-for-restaurant-compensation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-eligible: oneof<nothing, bool> # Flag that informs if the cancelled order is eligible for compensation
  --order-id: string # Id for the order
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-eligible-for-restaurant-compensation"
    body: {content_type: "application/json", kind: json, fields: [{name: IsEligible, var: is_eligible}, {name: OrderId, var: order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    is_eligible: $is_eligible, order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order ready for pickup
#
# PUT /order-is-ready-for-pickup
export def "put-order-is-ready-for-pickup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string@event-completer-1
  --timestamp: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/order-is-ready-for-pickup"
    body: {content_type: "application/json", kind: json, fields: [{name: Event, var: event}, {name: Timestamp, var: timestamp}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event: $event, timestamp: $timestamp
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order ready for preparation (async)
#
# POST /order-ready-for-preparation-async
export def "post-order-ready-for-preparation-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: string, Name?: string}
  --customer-notes: record
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --total-price: float # format: money
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-ready-for-preparation-async"
    body: {content_type: "application/json", kind: json, fields: [{name: Currency, var: currency}, {name: Customer, var: customer}, {name: CustomerNotes, var: customer_notes}, {name: Fulfilment, var: fulfilment}, {name: IsTest, var: is_test}, {name: Items, var: items}, {name: OrderId, var: order_id}, {name: Payment, var: payment}, {name: PlacedDate, var: placed_date}, {name: PriceBreakdown, var: price_breakdown}, {name: Restaurant, var: restaurant}, {name: TotalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    currency: $currency, customer: $customer, customer_notes: $customer_notes, fulfilment: $fulfilment, is_test: $is_test, items: $items, order_id: $order_id, payment: $payment, placed_date: $placed_date, price_breakdown: $price_breakdown, restaurant: $restaurant, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order ready for preparation (sync)
#
# POST /order-ready-for-preparation-sync
export def "post-order-ready-for-preparation-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: string, Name?: string}
  --customer-notes: record
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --total-price: float # format: money
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-ready-for-preparation-sync"
    body: {content_type: "application/json", kind: json, fields: [{name: Currency, var: currency}, {name: Customer, var: customer}, {name: CustomerNotes, var: customer_notes}, {name: Fulfilment, var: fulfilment}, {name: IsTest, var: is_test}, {name: Items, var: items}, {name: OrderId, var: order_id}, {name: Payment, var: payment}, {name: PlacedDate, var: placed_date}, {name: PriceBreakdown, var: price_breakdown}, {name: Restaurant, var: restaurant}, {name: TotalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    currency: $currency, customer: $customer, customer_notes: $customer_notes, fulfilment: $fulfilment, is_test: $is_test, items: $items, order_id: $order_id, payment: $payment, placed_date: $placed_date, price_breakdown: $price_breakdown, restaurant: $restaurant, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order rejected
#
# POST /order-rejected
export def "post-order-rejected" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string
  --rejected-at: string # format: date-time
  --rejected-by: string
  --rejected-reason: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-rejected"
    body: {content_type: "application/json", kind: json, fields: [{name: Event, var: event}, {name: RejectedAt, var: rejected_at}, {name: RejectedBy, var: rejected_by}, {name: RejectedReason, var: rejected_reason}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    event: $event, rejected_at: $rejected_at, rejected_by: $rejected_by, rejected_reason: $rejected_reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order requires delivery acceptance
#
# PUT /order-requires-delivery-acceptance
export def "put-order-requires-delivery-acceptance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/order-requires-delivery-acceptance"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Order time updated
#
# POST /order-time-updated
export def "post-order-time-updated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --day-of-week: string@day-of-week-completer # The day of the week that has been updated. (format: enum)
  --lower-bound-minutes: int # Order time lower bound value, in minutes. (format: int32)
  --restaurant-id: string # The Just Eat restaurant ID
  --service-type: string@service-type-completer # Service type of the order time. (format: enum)
  --upper-bound-minutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/order-time-updated"
    body: {content_type: "application/json", kind: json, fields: [{name: dayOfWeek, var: day_of_week}, {name: lowerBoundMinutes, var: lower_bound_minutes}, {name: restaurantId, var: restaurant_id}, {name: serviceType, var: service_type}, {name: upperBoundMinutes, var: upper_bound_minutes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    day_of_week: $day_of_week, lower_bound_minutes: $lower_bound_minutes, restaurant_id: $restaurant_id, service_type: $service_type, upper_bound_minutes: $upper_bound_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create order
#
# POST /orders
# Returns: record<OrderId: string>
export def "post-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-api-version: float # The api version to use. Version 2.0 is the only available version. (default: 1, e.g. 2)
  customer: record # shape: {Address: record, DisplayPhoneNumber?: string, Email?: string, Name: string, PhoneNumber: string}
  --customer-notes: record # e.g. {NoteForDelivery: Red door, NoteForRestaurant: Make it spicy} — shape: {NoteForDelivery?: string, NoteForRestaurant?: string}
  --friendly-order-reference: string
  fulfilment: record # e.g. {DueAsap: false, DueDate: 2020-01-01T09:00:00.000Z, Method: Delivery} — shape: {DueAsap?: bool, DueDate: string, Method: "Delivery"|"Collection"}
  --is-test: oneof<nothing, bool>
  items: list # item shape: {Items?: list, Name: string, Quantity: int, Reference: string, TotalPrice: float, UnitPrice?: int}
  order_reference: string
  payment: record # e.g. {Fees: [{Type: card, Value: 0.25}, {Type: delivery, Value: 3.5}], Lines: [{LastCardDigits: 1234, Paid: true, ServiceFee: 0, Type: Card, Value: 19.95}], Tips: [{Type: driver, Value: 2.5}]} — shape: {Fees?: list, Lines: list, PaidDate?: string, Taxes?: list, Tips?: list}
  restaurant: any
  total_price: float # format: double
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/orders"
    header: [{name: x-je-api-version, var: x_je_api_version}]
    body: {content_type: "application/json", kind: json, fields: [{name: Customer, var: customer}, {name: CustomerNotes, var: customer_notes}, {name: FriendlyOrderReference, var: friendly_order_reference}, {name: Fulfilment, var: fulfilment}, {name: IsTest, var: is_test}, {name: Items, var: items}, {name: OrderReference, var: order_reference}, {name: Payment, var: payment}, {name: Restaurant, var: restaurant}, {name: TotalPrice, var: total_price}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    x_je_api_version: $x_je_api_version, customer: $customer, customer_notes: $customer_notes, friendly_order_reference: $friendly_order_reference, fulfilment: $fulfilment, is_test: $is_test, items: $items, order_reference: $order_reference, payment: $payment, restaurant: $restaurant, total_price: $total_price
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update current driver locations (bulk upload)
#
# PUT /orders/deliverystate/driverlocation
export def "put-orders-deliverystate-driverlocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/deliverystate/driverlocation"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept order
#
# PUT /orders/{orderId}/accept
export def "put-orders-order-id-accept" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-accepted-for: string # format: date-time
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/accept"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: TimeAcceptedFor, var: time_accepted_for}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, time_accepted_for: $time_accepted_for
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel order
#
# PUT /orders/{orderId}/cancel
export def "put-orders-order-id-cancel" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Reason why this order is being cancelled.
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/cancel"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Complete order
#
# POST /orders/{orderId}/complete
export def "post-orders-order-id-complete" [
  order_id: string
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
    path: "/orders/{orderId}/complete"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with driver at delivery address details
#
# PUT /orders/{orderId}/deliverystate/atdeliveryaddress
export def "put-orders-order-id-deliverystate-atdeliveryaddress" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/atdeliveryaddress"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with driver at restaurant details
#
# PUT /orders/{orderId}/deliverystate/atrestaurant
export def "put-orders-order-id-deliverystate-atrestaurant" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the Eta calculated timestamp. (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/atrestaurant"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EtaAtDeliveryAddress, var: eta_at_delivery_address}, {name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, eta_at_delivery_address: $eta_at_delivery_address, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the driver's estimated time to arrive at the Restaurant
#
# PUT /orders/{orderId}/deliverystate/atrestauranteta
export def "put-orders-order-id-deliverystate-atrestauranteta" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-guess: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time)
  --estimated-at: string # This is the time at which you are doing the estimation (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/atrestauranteta"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: bestGuess, var: best_guess}, {name: estimatedAt, var: estimated_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, best_guess: $best_guess, estimated_at: $estimated_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with delivered details
#
# PUT /orders/{orderId}/deliverystate/delivered
export def "put-orders-order-id-deliverystate-delivered" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/delivered"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with driver assigned details
#
# PUT /orders/{orderId}/deliverystate/driverassigned
export def "put-orders-order-id-deliverystate-driverassigned" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string # This should represent the driver's contact number. (e.g. 07123456789)
  --driver-name: string # This should represent the driver's name. (e.g. David)
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the driver assigned timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
  --vehicle-details: record # shape: {Vehicle?: string, VehicleRegistration?: string}
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/driverassigned"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EtaAtDeliveryAddress, var: eta_at_delivery_address}, {name: EtaAtRestaurant, var: eta_at_restaurant}, {name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}, {name: VehicleDetails, var: vehicle_details}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, driver_contact_number: $driver_contact_number, driver_name: $driver_name, eta_at_delivery_address: $eta_at_delivery_address, eta_at_restaurant: $eta_at_restaurant, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset, vehicle_details: $vehicle_details
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the driver's current location
#
# PUT /orders/{orderId}/deliverystate/driverlocation
export def "put-orders-order-id-deliverystate-driverlocation" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the location updated timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/driverlocation"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EtaAtDeliveryAddress, var: eta_at_delivery_address}, {name: EtaAtRestaurant, var: eta_at_restaurant}, {name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, eta_at_delivery_address: $eta_at_delivery_address, eta_at_restaurant: $eta_at_restaurant, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with driver unassigned details
#
# PUT /orders/{orderId}/deliverystate/driverunassigned
export def "put-orders-order-id-deliverystate-driverunassigned" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # This should represent the comment on the unassignment. (e.g. Order was not ready)
  --driver-contact-number: string # This should represent the driver's contact number. (e.g. 07123456789)
  --driver-name: string # This should represent the driver's name. (e.g. David McDriverson)
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --reason: string # This should represent the delivery partner's reason for unassigning themselves from the order. (e.g. package_not_ready)
  --time-stamp-with-utc-offset: string # This should represent the driver unassigned timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --unassigned-by: string # This should represent the actor who triggered unassignment. (e.g. operation)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/driverunassigned"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comment, var: comment}, {name: DriverContactNumber, var: driver_contact_number}, {name: DriverName, var: driver_name}, {name: EtaAtDeliveryAddress, var: eta_at_delivery_address}, {name: EtaAtRestaurant, var: eta_at_restaurant}, {name: "Location:", var: location}, {name: Reason, var: reason}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}, {name: UnassignedBy, var: unassigned_by}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, comment: $comment, driver_contact_number: $driver_contact_number, driver_name: $driver_name, eta_at_delivery_address: $eta_at_delivery_address, eta_at_restaurant: $eta_at_restaurant, location: $location, reason: $reason, time_stamp_with_utc_offset: $time_stamp_with_utc_offset, unassigned_by: $unassigned_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order with driver on its way details
#
# PUT /orders/{orderId}/deliverystate/onitsway
export def "put-orders-order-id-deliverystate-onitsway" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --estimated-arrival-time: string # This should represent the delivery partner's best guess at when the driver will arrive at the customer's address. In other words, it should not just contain the delivery time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the driver on its ways timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/deliverystate/onitsway"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: EstimatedArrivalTime, var: estimated_arrival_time}, {name: Location, var: location}, {name: TimeStampWithUtcOffset, var: time_stamp_with_utc_offset}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, estimated_arrival_time: $estimated_arrival_time, location: $location, time_stamp_with_utc_offset: $time_stamp_with_utc_offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update order ETA
#
# PUT /orders/{orderId}/duedate
export def "put-orders-order-id-duedate" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --due-date: string # The updated ETA for the order (format: date-time)
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/duedate"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: DueDate, var: due_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, due_date: $due_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Ignore order
#
# PUT /orders/{orderId}/ignore
export def "put-orders-order-id-ignore" [
  order_id: string
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
    method: put
    path: "/orders/{orderId}/ignore"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark order as ready for collection
#
# POST /orders/{orderId}/readyforcollection
export def "post-orders-order-id-readyforcollection" [
  order_id: string
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
    path: "/orders/{orderId}/readyforcollection"
    path_params: [{name: orderId, var: order_id}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reject order
#
# PUT /orders/{orderId}/reject
export def "put-orders-order-id-reject" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Reason why this order is being rejected.
]: any -> any {
  $in | http-request {
    method: put
    path: "/orders/{orderId}/reject"
    path_params: [{name: orderId, var: order_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: Message, var: message}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id, message: $message
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Response to Late Order Update Request
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateorder/restaurantresponse
export def "post-orders-tenant-order-id-consumerqueries-lateorder-restaurantresponse" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --additional-delivery-time-to-add-minutes: int # The amount of time to add to the current delivery estimate in minutes
  --late-order-status: string@late-order-status-completer # The updated later order query status
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/{tenant}/{orderId}/consumerqueries/lateorder/restaurantresponse"
    path_params: [{name: tenant, var: tenant}, {name: orderId, var: order_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: additionalDeliveryTimeToAddMinutes, var: additional_delivery_time_to_add_minutes}, {name: lateOrderStatus, var: late_order_status}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    tenant: $tenant, order_id: $order_id, authorization: $authorization, additional_delivery_time_to_add_minutes: $additional_delivery_time_to_add_minutes, late_order_status: $late_order_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update late order compensation request with Restaurant response
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateordercompensation/restaurantresponse
export def "post-orders-tenant-order-id-consumerqueries-lateordercompensation-restaurantresponse" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --accepted-amount: int # The monetary amount of compensation granted, in cents/pence. Required when `isAccepted = true`.
  --is-accepted: oneof<nothing, bool> # Flag to indicate whether a compensation request has been accepted or rejected.
  --body-order-id: string # The ID of the late order compensation request that this response relates to. (spec name: orderId)
  --rejected-reason-code: string@rejected-reason-code-completer # - `BadTraffic` : The driver was stuck in heavy traffic, sorry. - `BadWeather` : The bad weather was delaying our deliveries, sorry. - `BusierThanExpected` : Our restaurant was busier than we expected. - `CompensatedWithItem` : We gave you something from the menu free of charge to make up for it. - `NoReason` : We're really sorry your order was late. We hope you enjoyed your food.
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/{tenant}/{orderId}/consumerqueries/lateordercompensation/restaurantresponse"
    path_params: [{name: tenant, var: tenant}, {name: orderId, var: order_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: acceptedAmount, var: accepted_amount}, {name: isAccepted, var: is_accepted}, {name: orderId, var: body_order_id}, {name: rejectedReasonCode, var: rejected_reason_code}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    tenant: $tenant, order_id: $order_id, authorization: $authorization, accepted_amount: $accepted_amount, is_accepted: $is_accepted, body_order_id: $body_order_id, rejected_reason_code: $rejected_reason_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Compensation requests
#
# POST /orders/{tenant}/{orderId}/restaurantqueries/compensation
export def "post-orders-tenant-order-id-restaurantqueries-compensation" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --comments: string # Any other comments to add to the request
  --reason-code: string@reason-code-completer # The reason why compensation is due
]: any -> any {
  $in | http-request {
    method: post
    path: "/orders/{tenant}/{orderId}/restaurantqueries/compensation"
    path_params: [{name: tenant, var: tenant}, {name: orderId, var: order_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: Comments, var: comments}, {name: ReasonCode, var: reason_code}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tenant: $tenant, order_id: $order_id, authorization: $authorization, comments: $comments, reason_code: $reason_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Customer Requested Redelivery
#
# PUT /redelivery-requested
export def "put-redelivery-requested" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string
  --order-id: string
  --tenant: string
  --update: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/redelivery-requested"
    body: {content_type: "application/json", kind: json, fields: [{name: Notes, var: notes}, {name: OrderId, var: order_id}, {name: Tenant, var: tenant}, {name: Update, var: update}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    notes: $notes, order_id: $order_id, tenant: $tenant, update: $update
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restaurant Offline Status
#
# PUT /restaurant-offline-status
export def "put-restaurant-offline-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --is-offline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --restaurant-id: string # The unique identifier of the restaurant that has their offline status changed.
  --tenant: string@tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  $in | http-request {
    method: put
    path: "/restaurant-offline-status"
    body: {content_type: "application/json", kind: json, fields: [{name: AllowRestaurantOverride, var: allow_restaurant_override}, {name: IsOffline, var: is_offline}, {name: RestaurantId, var: restaurant_id}, {name: Tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_restaurant_override: $allow_restaurant_override, is_offline: $is_offline, restaurant_id: $restaurant_id, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Restaurant Online Status
#
# PUT /restaurant-online-status
export def "put-restaurant-online-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --is-offline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --restaurant-id: string # The unique identifier of the restaurant that has their offline status changed.
  --tenant: string@tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  $in | http-request {
    method: put
    path: "/restaurant-online-status"
    body: {content_type: "application/json", kind: json, fields: [{name: AllowRestaurantOverride, var: allow_restaurant_override}, {name: IsOffline, var: is_offline}, {name: RestaurantId, var: restaurant_id}, {name: Tenant, var: tenant}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    allow_restaurant_override: $allow_restaurant_override, is_offline: $is_offline, restaurant_id: $restaurant_id, tenant: $tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get restaurants by location
#
# GET /restaurants/bylatlong
# operationId: SearchByLocation
export def "search-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # Filter search results to only include restaurants that deliver to the specified location (required)
  --longitude: float # Filter search results to only include restaurants that deliver to the specified location (required)
  --cuisine: string # Filter search results to only include restaurants that offer the specified cuisine
  --restaurant-name: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brand-name: string # Filter search results to only include restaurants of the specified brand
  --authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner (required)
  --accept-tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  http-request {
    method: get
    path: "/restaurants/bylatlong"
    query: [{name: latitude, var: latitude, required: true}, {name: longitude, var: longitude, required: true}, {name: cuisine, var: cuisine}, {name: restaurantName, var: restaurant_name}, {name: brandName, var: brand_name}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Accept-Tenant, var: accept_tenant}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    latitude: $latitude, longitude: $longitude, cuisine: $cuisine, restaurant_name: $restaurant_name, brand_name: $brand_name, authorization: $authorization, accept_tenant: $accept_tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get restaurants by postcode
#
# GET /restaurants/bypostcode/{postcode}
# operationId: SearchByPostcode
export def "search-by-postcode" [
  postcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cuisine: string # Filter search results to only include restaurants that offer the specified cuisine
  --restaurant-name: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brand-name: string # Filter search results to only include restaurants of the specified brand
  --authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner
  --accept-tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  http-request {
    method: get
    path: "/restaurants/bypostcode/{postcode}"
    path_params: [{name: postcode, var: postcode}]
    query: [{name: cuisine, var: cuisine}, {name: restaurantName, var: restaurant_name}, {name: brandName, var: brand_name}]
    header: [{name: Authorization, var: authorization}, {name: Accept-Tenant, var: accept_tenant}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    postcode: $postcode, cuisine: $cuisine, restaurant_name: $restaurant_name, brand_name: $brand_name, authorization: $authorization, accept_tenant: $accept_tenant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set ETA for pickup
#
# PUT /restaurants/driver/eta
# Returns: record<ignoredRestaurantIds: list<string>>
export def "put-restaurants-driver-eta" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restaurants/driver/eta"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get product catalogue
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue
# Returns: record<currency: string, description: string, name: string, restaurantId: string>
export def "get-restaurants-tenant-restaurant-id-catalogue" [
  tenant: string
  restaurant_id: string
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
    path: "/restaurants/{tenant}/{restaurantId}/catalogue"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all availabilities
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/availabilities
# Returns: record<paging: record<cursors: record<after: string>>, availabilities: table<description: string, id: string, name: string, serviceTypes: list, times: list>>
export def "get-restaurants-tenant-restaurant-id-catalogue-availabilities" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of availabilities to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/availabilities"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all categories
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories
# Returns: record<paging: record<cursors: record<after: string>>, categories: table<description: string, id: string, name: string>>
export def "get-restaurants-tenant-restaurant-id-catalogue-categories" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of categories to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/categories"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all category item IDs
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories/{categoryId}/items
# Returns: record<paging: record<cursors: record<after: string>>, itemIds: list<string>>
export def "get-restaurants-tenant-restaurant-id-catalogue-categories-category-id-items" [
  tenant: string
  restaurant_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of item IDs to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/categories/{categoryId}/items"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: categoryId, var: category_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, category_id: $category_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all menu items
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items
# Returns: record<paging: record<cursors: record<after: string>>, items: table<description: string, id: string, labels: list, name: string, requireOtherProducts: bool, type: string>>
export def "get-restaurants-tenant-restaurant-id-catalogue-items" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/items"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all menu item deal groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups
# Returns: record<paging: record<cursors: record<after: string>>, dealGroups: table<id: string, name: string, numberOfChoices: int>>
export def "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: itemId, var: item_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, item_id: $item_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all deal item variations for a deal group
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups/{dealGroupId}/dealitemvariations
# Returns: record<paging: record<cursors: record<after: string>>, dealItemVariations: table<additionPrice: float, dealItemVariationId: string, maxChoices: int, minChoices: int>>
export def "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-dealgroups-deal-group-id-dealitemvariations" [
  tenant: string
  restaurant_id: string
  item_id: string
  deal_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups/{dealGroupId}/dealitemvariations"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: itemId, var: item_id}, {name: dealGroupId, var: deal_group_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, item_id: $item_id, deal_group_id: $deal_group_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all menu item modifier groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/modifiergroups
# Returns: record<paging: record<cursors: record<after: string>>, modifierGroups: table<id: string, maxChoices: int, minChoices: int, modifiers: list, name: string>>
export def "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-modifiergroups" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/modifiergroups"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: itemId, var: item_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, item_id: $item_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all menu item variations
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/variations
# Returns: record<paging: record<cursors: record<after: string>>, variations: table<availabilityIds: list, basePrice: float, dealGroupsIds: list, dealOnly: bool, id: string, kitchenNumber: string, modifierGroupsIds: list, name: string, type: string>>
export def "get-restaurants-tenant-restaurant-id-catalogue-items-item-id-variations" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (required, format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/variations"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: itemId, var: item_id}]
    query: [{name: limit, var: limit, required: true}, {name: after, var: after}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, item_id: $item_id, limit: $limit, after: $after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get claims
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims
# Returns: record<claims: table<affectedItems: list, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record, restaurantResponse: record, state: string, submittedDate: string, totalClaimed: float>>
export def "get-restaurants-tenant-restaurant-id-customerclaims" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date limiter (nullable, format: date-time)
  --to-date: string # End date limiter (nullable, format: date-time)
  --limit: int # Pagination limit (nullable, format: int32, default: 20)
  --offset: int # Pagination offset (nullable, format: int32)
  --hdr-accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/customerclaims"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    query: [{name: fromDate, var: from_date}, {name: toDate, var: to_date}, {name: limit, var: limit}, {name: offset, var: offset}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, from_date: $from_date, to_date: $to_date, limit: $limit, offset: $offset, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get order claim
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims/{id}
# Returns: record<affectedItems: table<additionalContext: string, decision: string, id: string, name: string, quantity: float, totalClaimed: float, unitPrice: float>, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record<decision: string, resolvedChannel: string, resolvedDate: string, totalClaimedAccepted: float>, restaurantResponse: record<decision: string, items: list<record>, justification: record<comments: string, reason: string>>, state: string, submittedDate: string, totalClaimed: float>
export def "get-restaurants-tenant-restaurant-id-customerclaims-id" [
  tenant: string
  restaurant_id: string
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
  --hdr-accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1) (spec name: Accept)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/customerclaims/{id}"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: id, var: id}]
    header: [{name: Accept, var: hdr_accept}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, id: $id, hdr_accept: $hdr_accept
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Submit a restaurant response for the claim
#
# POST /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse
export def "post-restaurants-tenant-restaurant-id-customerclaims-id-restaurantresponse" [
  tenant: string
  restaurant_id: string
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
  --content-type: string # Indicates the representation of the request body the client is sending (including version) (required, e.g. application/json;v=1)
  --decision: string@decision-completer # Decision on the claim
  --items: list # Decisions on the items of a claim (nullable) — item shape: {decision?: "Accepted"|"Rejected", id?: string}
  --justification: record # The reason of the claim rejection and optional comments from the restaurant (nullable, e.g. {comments: The food was packed properly, reason: Other}) — shape: {comments?: string, reason?: "AlreadyRefunded"|"ItemReplaced"|"PartialRefundRequired"|"WasNotMissing"|"WillRedeliver"|"OrderWasHot"|"OrderWasOnTime"|"OrderWasPacked"|"FoodWasIntact"|"AddExtraItem"|"Other"}
]: any -> any {
  $in | http-request {
    method: post
    path: "/restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: decision, var: decision}, {name: items, var: items}, {name: justification, var: justification}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, id: $id, content_type: $content_type, decision: $decision, items: $items, justification: $justification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add reason and comments to the response
#
# PUT /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse/justification
export def "put-restaurants-tenant-restaurant-id-customerclaims-id-restaurantresponse-justification" [
  tenant: string
  restaurant_id: string
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
  --content-type: string # Indicates the representation of the request body the client is sending (including version) (required, e.g. application/json;v=1)
  --comments: string # Comment from the restaurant owner in case they rejected at least one of the items and want to type their own rejection reason (nullable)
  --reason: string@reason-completer-1 # One of the predefined reasons
]: any -> any {
  $in | http-request {
    method: put
    path: "/restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse/justification"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: id, var: id}]
    header: [{name: Content-Type, var: content_type, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: comments, var: comments}, {name: reason, var: reason}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, id: $id, content_type: $content_type, comments: $comments, reason: $reason
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Restaurant Fees
#
# GET /restaurants/{tenant}/{restaurantId}/fees
# Returns: record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>>
export def "get-restaurants-tenant-restaurant-id-fees" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Request header string that allows the server to identify the application making the request.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/fees"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    header: [{name: User-Agent, var: user_agent}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, user_agent: $user_agent
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or Update Restaurant Fees
#
# PUT /restaurants/{tenant}/{restaurantId}/fees
# Returns: record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>>
export def "put-restaurants-tenant-restaurant-id-fees" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Request header string that allows the server to identify the application making the request.
  --bag-fee: record # The object which encapsulates a Fee (e.g. {description: A charge for bags in delivery, serviceTypes: {collection: {amount: 5}, default: {amount: 0}, delivery: {amount: 10}}}) — shape: {description?: string, serviceTypes?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restaurants/{tenant}/{restaurantId}/fees"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    header: [{name: User-Agent, var: user_agent}]
    body: {content_type: "application/json", kind: json, fields: [{name: bagFee, var: bag_fee}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, user_agent: $user_agent, bag_fee: $bag_fee
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the latest version of the restaurant's full menu
#
# GET /restaurants/{tenant}/{restaurantId}/menu
export def "get-restaurants-tenant-restaurant-id-menu" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. Bearer ABCDE123456789 (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/menu"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [301]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update a menu
#
# PUT /restaurants/{tenant}/{restaurantId}/menu
# Returns: record<correlationId: string>
# operationId: putMenuForIngestion
export def "put-menu-for-ingestion" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --content-type: string # Used to denote the version of the menu payload within the body, will default to latest if not supplied e.g. application/=1.0
  --currency: string # The currency of the items on the menu in ISO 4217 format, i.e. GBP, EUR or AUD
  --description: string # A top level description for the menu.
  --name: string # The name of the restaurant.
  --body-restaurant-id: string # A unique identifier at tenant level for a given restaurant. (spec name: restaurantId)
  --availabilities: list # A set of availabilities that can later be referenced by individual menu items. — item shape: {description?: string, id?: string, name?: string, serviceTypes?: list<string>, times?: list}
  --categories: list # A set of categories that appear on the menu. — item shape: {description?: string, id?: string, name?: string, itemIds?: list<string>}
  --items: list # All of the menu items within the menu. — item shape: {description?: string, id?: string, labels?: list<string>, name?: string, requireOtherProducts?: bool, type?: "menuItem"|"deal", dealGroups?: list, imageUrl?: string, modifierGroups?: list, variations?: list}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restaurants/{tenant}/{restaurantId}/menu"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    header: [{name: Authorization, var: authorization, required: true}, {name: Content-Type, var: content_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: currency, var: currency}, {name: description, var: description}, {name: name, var: name}, {name: restaurantId, var: body_restaurant_id}, {name: availabilities, var: availabilities}, {name: categories, var: categories}, {name: items, var: items}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, authorization: $authorization, content_type: $content_type, currency: $currency, description: $description, name: $name, body_restaurant_id: $body_restaurant_id, availabilities: $availabilities, categories: $categories, items: $items
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the restaurant's delivery and collection lead times
#
# GET /restaurants/{tenant}/{restaurantId}/ordertimes
# Returns: table<dayOfWeek: string, lowerBoundMinutes: int, serviceType: string, upperBoundMinutes: int>
# operationId: GetOrderTimes
export def "get-order-times" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # OAuth2 token issued for logged in restaurant (required)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/restaurants/{tenant}/{restaurantId}/ordertimes"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, authorization: $authorization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the restaurant's delivery and collection lead times
#
# PUT /restaurants/{tenant}/{restaurantId}/ordertimes/{dayOfWeek}/{serviceType}
# operationId: UpdateOrderTime
export def "update-order-time" [
  tenant: string
  restaurant_id: string
  day_of_week: string@day-of-week-completer
  service_type: string@service-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # OAuth2 token issued for logged in restaurant OR API token for third party, in the format `Bearer {api_key}` (required)
  --lower-bound-minutes: int # Order time lower bound value, in minutes. (format: int32)
  --upper-bound-minutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/restaurants/{tenant}/{restaurantId}/ordertimes/{dayOfWeek}/{serviceType}"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}, {name: dayOfWeek, var: day_of_week}, {name: serviceType, var: service_type}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: lowerBoundMinutes, var: lower_bound_minutes}, {name: upperBoundMinutes, var: upper_bound_minutes}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, day_of_week: $day_of_week, service_type: $service_type, authorization: $authorization, lower_bound_minutes: $lower_bound_minutes, upper_bound_minutes: $upper_bound_minutes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get service times
#
# GET /restaurants/{tenant}/{restaurantId}/servicetimes
# Returns: record<serviceTimes: record<friday: record<collection: list, delivery: list>, monday: record<collection: list, delivery: list>, saturday: record<collection: list, delivery: list>, sunday: record<collection: list, delivery: list>, thursday: record<collection: list, delivery: list>, tuesday: record<collection: list, delivery: list>, wednesday: record<collection: list, delivery: list>>>
# operationId: getRestaurantServiceTimes
export def "get-restaurant-service-times" [
  tenant: string
  restaurant_id: string
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
    path: "/restaurants/{tenant}/{restaurantId}/servicetimes"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create or update service times
#
# PUT /restaurants/{tenant}/{restaurantId}/servicetimes
# Returns: record<serviceTimes: record<friday: record<collection: list, delivery: list>, monday: record<collection: list, delivery: list>, saturday: record<collection: list, delivery: list>, sunday: record<collection: list, delivery: list>, thursday: record<collection: list, delivery: list>, tuesday: record<collection: list, delivery: list>, wednesday: record<collection: list, delivery: list>>>
# operationId: putRestaurantServiceTimes
export def "put-restaurant-service-times" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-times: record # The desired times at which a restaurant is in service — shape: {friday?: record, monday?: record, saturday?: record, sunday?: record, thursday?: record, tuesday?: record, wednesday?: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/restaurants/{tenant}/{restaurantId}/servicetimes"
    path_params: [{name: tenant, var: tenant}, {name: restaurantId, var: restaurant_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: serviceTimes, var: service_times}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, restaurant_id: $restaurant_id, service_times: $service_times
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get auto-completed search terms
#
# GET /search/autocomplete/{tenant}
# Returns: record<terms: table<classification: string, term: string>>
export def "get-search-autocomplete-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # User's search term - at least one character required (required)
  --latlong: list<float> # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (required, e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of auto-completed terms returned by the API. Defaults to 7. Valid values 1 - 10 (format: integer)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/autocomplete/{tenant}"
    path_params: [{name: tenant, var: tenant}]
    query: [{name: searchTerm, var: search_term, required: true}, {name: latlong, var: latlong, style: csv, required: true}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, search_term: $search_term, latlong: $latlong, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search restaurants
#
# GET /search/restaurants/{tenant}
# Returns: record<restaurants: table<isSponsored: bool, products: list, restaurantId: string>>
export def "get-search-restaurants-tenant" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # User's search term. (required)
  --latlong: list<float> # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (required, e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of restaurants returned by the API. Valid values are numbers between 1 and 500. If not provided, the limit defaults to 300. (format: integer)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/search/restaurants/{tenant}"
    path_params: [{name: tenant, var: tenant}]
    query: [{name: searchTerm, var: search_term, required: true}, {name: latlong, var: latlong, style: csv, required: true}, {name: limit, var: limit}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, search_term: $search_term, latlong: $latlong, limit: $limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Send to POS failed
#
# POST /send-to-pos-failed
export def "post-send-to-pos-failed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string
]: any -> any {
  $in | http-request {
    method: post
    path: "/send-to-pos-failed"
    body: {content_type: "application/json", kind: json, fields: [{name: OrderId, var: order_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order_id: $order_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create Offline Event
#
# POST /v1/{tenant}/restaurants/event/offline
# Returns: record<restaurantEventId: string, restaurantIds: string>
@deprecated --flag category
export def "post-v1-tenant-restaurants-event-offline" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-requester: string # Name of the user or system creating the event. Used for auditing purposes (required)
  --x-je-user-role: string@x-je-user-role-completer # required
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to delete this event, regardless of who raised it.
  --category: string # A free text category used to group multiple events. This field is not intended to be used by clients. (DEPRECATED)
  --duration: string # Either a timespan in the HH:mm format or `untilTomorrow` (this will be the next day at 4:30 am +/- 10 minutes local time). Note if both duration and `endDate` are specified duration takes precedence.
  --end-date: string # ISO 8601 format of the end datetime of the offline event. (nullable, format: date-time)
  --legacy-temp-offline-type: string@legacy-temp-offline-type-completer # - `Unset` : Legacy value meaning online. - `None` : Legacy value meaning online. - `TempOffline` : The restaurant will go temporarily offline, typically for an undetermined amount of time (no end date). - `ClosedToday` : The restaurant will closed for the day and the event will end the next morning. - `ClosedDueToEvent` : The restaurant will go offline for an event (e.g. a holiday), these events will typically have an end time. - `FailedJctConnection` : The restaurant will go offline due to the POS device losing connection. - `NoTrOverride` : The restaurant will go offline for another reason that the restaurant cannot override. - `IgnoredOrders` : The restaurant will go offline due to ignoring orders. (default: ClosedDueToEvent)
  name: string # Name of the offline event to be created.
  reason: string # The reason for creating the offline event.
  restaurant_ids: string # A comma separated list of the IDs of the restaurants to include in the offline event. No limit to the number accepted by the endpoint, but unexpected behaviour mat occur at more than 500 IDs.
  start_date: string # ISO 8601 format of the start datetime of the offline event. (format: date-time)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{tenant}/restaurants/event/offline"
    path_params: [{name: tenant, var: tenant}]
    header: [{name: X-JE-Requester, var: x_je_requester, required: true}, {name: X-JE-User-Role, var: x_je_user_role, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: allowRestaurantOverride, var: allow_restaurant_override, required: true}, {name: category, var: category}, {name: duration, var: duration}, {name: endDate, var: end_date}, {name: legacyTempOfflineType, var: legacy_temp_offline_type}, {name: name, var: name}, {name: reason, var: reason}, {name: restaurantIds, var: restaurant_ids}, {name: startDate, var: start_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    tenant: $tenant, x_je_requester: $x_je_requester, x_je_user_role: $x_je_user_role, allow_restaurant_override: $allow_restaurant_override, category: $category, duration: $duration, end_date: $end_date, legacy_temp_offline_type: $legacy_temp_offline_type, name: $name, reason: $reason, restaurant_ids: $restaurant_ids, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete Offline Event
#
# DELETE /v1/{tenant}/restaurants/{id}/event/offline
export def "delete-v1-tenant-restaurants-id-event-offline" [
  tenant: string
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
  --x-je-requester: string # Name of the user or system creating the event. Used for auditing purposes (required)
  --x-je-user-role: string@x-je-user-role-completer # The role the user or system creating the event has assumed. (required)
]: nothing -> any {
  http-request {
    method: delete
    path: "/v1/{tenant}/restaurants/{id}/event/offline"
    path_params: [{name: tenant, var: tenant}, {name: id, var: id}]
    header: [{name: X-JE-Requester, var: x_je_requester, required: true}, {name: X-JE-User-Role, var: x_je_user_role, required: true}]
    accept: ["application/json"]
    ok: [200, 202]
    auth: bearer
  } {
    tenant: $tenant, id: $id, x_je_requester: $x_je_requester, x_je_user_role: $x_je_user_role
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delivery Attempt Failed
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery
export def "post-tenant-orders-order-id-queries-attempteddelivery" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --reason-code: string@reason-code-completer-1 # The reason the attempted delivery event was created
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenant}/orders/{orderId}/queries/attempteddelivery"
    path_params: [{name: tenant, var: tenant}, {name: orderId, var: order_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: ReasonCode, var: reason_code}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, order_id: $order_id, authorization: $authorization, reason_code: $reason_code
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Request Redelivery of the Order
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery/resolution/redeliverorder
export def "post-tenant-orders-order-id-queries-attempteddelivery-resolution-redeliverorder" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789` (required)
  --new-due-date: string # Updated due date for delivery of the order (format: date-time)
  --status: string@status-completer # The current status of the order
]: any -> any {
  $in | http-request {
    method: post
    path: "/{tenant}/orders/{orderId}/queries/attempteddelivery/resolution/redeliverorder"
    path_params: [{name: tenant, var: tenant}, {name: orderId, var: order_id}]
    header: [{name: Authorization, var: authorization, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: NewDueDate, var: new_due_date}, {name: Status, var: status}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    tenant: $tenant, order_id: $order_id, authorization: $authorization, new_due_date: $new_due_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
