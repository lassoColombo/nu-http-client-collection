# Auto-generated client for SimplyRETS v1.0.0
# Source: https://api.apis.guru/v2/specs/simplyrets.com/1.0.0/swagger.json
# Auth: --token flag or $env.SIMPLYRETS_TOKEN

const CLIENT = {
  base_url: "https://api.simplyrets.com"
  token_env_var: "SIMPLYRETS_TOKEN"
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

def base-url-completer [] { ["https://api.simplyrets.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["commercial" "condominium" "farm" "land" "multifamily" "rental" "residential"] }
def sort-completer [] { ["-baths" "-beds" "-listdate" "-listprice" "baths" "beds" "listdate" "listprice"] }
def accept-completer [] { ["application/json" "application/vnd.simplyrets-v0.1+json"] }
def status-completer [] { ["Active" "ActiveUnderContract" "Closed" "ComingSoon" "Delete" "Expired" "Hold" "Incomplete" "Pending" "Withdrawn"] }
def subtype-completer [] { ["apartment" "boatslip" "cabin" "condominium" "deededparking" "duplex" "manufacturedhome" "manufacturedonland" "ownyourown" "quadruplex" "singlefamilyresidence" "stockcooperative" "timeshare" "townhouse" "triplex"] }
def include-completer [] { ["agreement" "association" "garageSpaces" "maintenanceExpense" "parking" "pool" "rooms" "taxAnnualAmount" "taxYear"] }
def include-completer-1 [] { ["agreement" "association" "garageSpaces" "maintenanceExpense" "parking" "pool" "rooms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-openhouses: "table<description: string, endTime: string, inputId: any, listing: record<address: record, agent: record, association: record, coAgent: record, disclaimer: string, geo: record, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record, mlsId: int, modified: string, office: record, photos: list, privateRemarks: string, property: record, remarks: string, sales: record, school: record, showingInstructions: string, tax: record, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string>"
    get-openhouses-open-house-key: "record<description: string, endTime: string, inputId: any, listing: record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string>"
    get-properties: "table<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>"
    get-properties-mls-id: "record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record<cell: string, email: string, office: string>, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record<description: string, leased: string, spaces: int>, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-openhouses" "get-openhouses-open-house-key" "get-properties" "get-properties-mls-id" "commands"] | sort) } | get name | first)
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

# The SimplyRETS OpenHouses API
#
# GET /openhouses
# Returns: table<description: string, endTime: string, inputId: any, listing: record<address: record, agent: record, association: record, coAgent: record, disclaimer: string, geo: record, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record, mlsId: int, modified: string, office: record, photos: list, privateRemarks: string, property: record, remarks: string, sales: record, school: record, showingInstructions: string, tax: record, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string>
export def "get-openhouses" [
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
  --type: string@type-completer # Request listings by a specific property type. This defaults to Residential, and you can only specify one type in a single query.
  --listing-id: string # Request openhouses for a specific `listingId`.
  --cities: list<string> # Filter the openhouses returned by a list of valid cities. The `cities` query parameter is case-insensitive. The list of `cities` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --brokers: list<string> # Filter the listings returned by brokerage with a Broker ID. You can specific multiple broker parameters. Note, the Broker ID is provided by your MLS.
  --agent: string # Filter the listings returned by an agent ID. Note, the Agent ID is provided by your MLS.
  --minprice: int # Filter listings by a minimum price.
  --startdate: string # Scheduled date and time of the open house showing (format: date-time)
  --offset: int # Increase the offset parameter by the limit to go to the next "page" of listings. Also take a look at the Link HTTP Header for pre-built pagination. *NOTE:* Use the `lastId` parameter for pagination.
  --last-id: int # Used as a cursor for pagination.
  --limit: int # Set the number of listings to return in the response. This defaults to 20 listings, and can be a maximum of 500. To paginate through to the next page of listings, take a look at the `offset` parameter, or the Link in the HTTP Header.
  --sort: string@sort-completer # Sort the response by a specific field. Values starting with a minus (-) denote descending order, while the others are ascending.
  --include: list<string> # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/openhouses"
    query: [{name: type, var: type}, {name: listingId, var: listing_id}, {name: cities, var: cities, style: multi}, {name: brokers, var: brokers, style: multi}, {name: agent, var: agent}, {name: minprice, var: minprice}, {name: startdate, var: startdate}, {name: offset, var: offset}, {name: lastId, var: last_id}, {name: limit, var: limit}, {name: sort, var: sort}, {name: include, var: include, style: multi}]
    accept: ["application/json", "application/vnd.simplyrets-v0.1+json"]
    ok: [200]
    auth: basic
  } {
    type: $type, listing_id: $listing_id, cities: $cities, brokers: $brokers, agent: $agent, minprice: $minprice, startdate: $startdate, offset: $offset, last_id: $last_id, limit: $limit, sort: $sort, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Single OpenHouse Endpoint
#
# GET /openhouses/{openHouseKey}
# Returns: record<description: string, endTime: string, inputId: any, listing: record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>, openHouseId: string, openHouseKey: string, refreshments: string, startTime: string, type: string>
export def "get-openhouses-open-house-key" [
  open_house_key: int
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
  --include: list<string> # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/openhouses/{openHouseKey}"
    path_params: [{name: openHouseKey, var: open_house_key}]
    query: [{name: include, var: include, style: multi}]
    accept: ["application/json", "application/vnd.simplyrets-v0.1+json"]
    ok: [200]
    auth: basic
  } {
    open_house_key: $open_house_key, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# The SimplyRETS Listings API
#
# GET /properties
# Returns: table<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>
export def "get-properties" [
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
  --q: string # A textual keyword search. This parameter will search the following fields, when available: - listingId (This does _not_ search the `mlsId` field in the SimplyRETS response body) - street number - street name - mls area (major) - city - subdivision name - postal code
  --status: list<string>@status-completer # Request listings by a specific status. This parameter defaults to active and you can specify multiple statuses in a single query. Listing statuses depend on your MLS's availability. Below is a brief description of each status with possible synonyms which may map to your MLS-specific statuses - *Active*: Active Listing which is still on the market - *ActiveUnderContract*: An offer has been accepted but the listing is still on market. Synonyms: Accepting Backup Offers, Backup Offer, Active With Accepted. Synonyms: Offer, Backup, Contingent - *Pending*: An offer has been accepted and the listing is no longer on market. Synonyms: Offer Accepted, Under Contract - *Hold*: The listing has been withdrawn from the market, but a contract still exists between the seller and the listing member. Synonyms: Hold, Hold Do Not Show, Temp Off Market - *Withdrawn*: The listing has been withdrawn from the market, but a contract still exists between the seller and the listing member. Synonyms: Hold, Hold Do Not Show, Temp Off Market - *Closed*: The purchase agreement has been fulfilled or the lease agreement has been executed. Synonyms: Sold, Leased, Rented, Closed Sale - *Expired*: The listing contract has expired - *Delete*: The listing contract was never valid or other reason for the contract to be nullified. Synonyms: Kill, Zap - *Incomplete*: The listing has not yet be completely entered and is not yet published in the MLS. Synonyms: Draft, Partially Complted - *ComingSoon*
  --type: list<string>@type-completer # Request listings by a specific property type. This defaults to Residential and Rental. You can specify multiple property types in a single query.
  --subtype: list<string>@subtype-completer # Request listings by a specific property sub type. *NOTE* not all sub type filters are available for all vendors.
  --agent: string # Filter the listings returned by an agent ID. Note, the Agent ID is provided by your MLS. The co-listing agent is not included in this query parameter.
  --brokers: list<string> # Filter the listings returned by brokerage with a Broker ID. For some MLS areas, this is the ListOfficeId (Listing Office ID). You can specific multiple broker parameters. Note, this query parameter is only available if a Broker ID is provided by your MLS.
  --minprice: int # Filter listings by a minimum price.
  --maxprice: int # Filter listings by a maximum price
  --minarea: int # Filter listings by a minimum area size in Sq Ft.
  --maxarea: int # Filter listings by a maximum area size in Sq Ft.
  --minbaths: int # Filter listings by a minimum number of bathrooms.
  --maxbaths: int # Filter listings by a maximum number of bathrooms.
  --minbeds: int # Filter listings by a minimum number of bedrooms.
  --maxbeds: int # Filter listings by a maximum number of bedrooms.
  --maxdom: int # Filter listings by a maximum number of days on market. _Note that your MLS must provide Days on Market data._
  --minyear: int # Filter listings by a setting a minimum year built.
  --limit: int # Set the number of listings to return in the response. This defaults to 20 listings, and can be a maximum of 500. To paginate through to the next page of listings, take a look at the `offset` parameter, or the Link in the HTTP Header.
  --offset: int # Increase the offset parameter by the limit to go to the next "page" of listings. Also take a look at the Link HTTP Header for pre-built pagination. *NOTE:* Use the `lastId` field to paginate response *NOTE:* If you're offset is too high, you will receive an `HTTP 400 offset too high` error message.
  --last-id: int # Used as a cursor for pagination. When using `lastId`, the `sort` parameter will not work.
  --vendor: string # Used to specify the vendor (MLS) to search from. This parameter is required on multi-MLS apps, and you can only query one vendor at a time. To get your vendor id's make an OPTIONS request to https://api.simplyrets.com. `curl -XOPTIONS https://api.simplyrets.com/properties`
  --postal-codes: list<string> # Filter the listings returned by postal codes / zip code. You can specify multiple.
  --features: list<string> # Filter the listings by specific interior features. You can filter by multiple. For example, to filter trial listings by multiple features you can use, Return listings that are within a set of latitude longitude coordinates. For example, ``` Wet Bar High Ceiling ``` e.g. `https://simplyrets.com/services?features=Wet%20Bar&features=High%20Ceiling` The list of `features` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/properties`
  --water: string # Query water/waterfront listings only. Specify `true` to filter waterfront listings. If you specify `water=true`, all listings with any `waterfront` value will be queried. If you specify `water=false`, listings which are **NOT** waterfront listings will be queried. If you specify `water=LAKE+NAME` or another valid value contained in your feed, that value will be searched
  --neighborhoods: list<string> # Filter the listings returned by specific neighborhoods and subdivisions. You can specify multiple `neighborhoods` by using the query parameter multiple times. The `neighborhoods` query parameter is case-insensitive. The list of `neighborhoods` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/properties`
  --cities: list<string> # Filter the listings returned by specific cities. You can specify multiple `cities` query parameters. The `cities` query parameter is case-insensitive. The list of `cities` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --counties: list<string> # Filter the listings returned by specific counties. You can specify multiple `counties` parameters. The `counties` query parameter is case-insensitive. The list of `counties` provided by your RETS vendor can be seen by sending an `OPTIONS` request to the `/properties` endpoint: `curl -XOPTIONS -u simplyrets:simplyrets https://api.simplyrets.com/openhouses`
  --points: list<string> # Return listings that are within a set of latitude longitude coordinates. For example; ``` 29.723837,-95.69778 29.938275,-95.69778 29.938275,-95.32974 29.723837,-95.32974 ``` Note that some MLS's do not provide latitude and longitude for their listings, which is required for this parameter to work. In these cases, SimplyRETS offers a [Geocoding Addon](https://simplyrets.com/services#geocoding). Check out our [blog post](https://simplyrets.com/blog/interactive-map-search.html) on using the `points` parameter to build a map-based app in javascript.
  --include: list<string>@include-completer # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'taxAnnualAmount' include the annual tax amount - 'taxYear' include the tax year data - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available in the API response. In the future, fields which require an 'include' may become available by default.
  --sort: string@sort-completer # Sort the response by a specific field. Values starting with a minus (-) denote descending order, while the others are ascending.
  --count: int # When set to `false`, The `X-Total-Count` header will not be returned Counting the listings can contribute to slower API calls due to the extra queries that need to be run to get an exact count. Disabling count can increase query speeds.
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/properties"
    query: [{name: q, var: q}, {name: status, var: status, style: multi}, {name: type, var: type, style: multi}, {name: subtype, var: subtype, style: multi}, {name: agent, var: agent}, {name: brokers, var: brokers, style: multi}, {name: minprice, var: minprice}, {name: maxprice, var: maxprice}, {name: minarea, var: minarea}, {name: maxarea, var: maxarea}, {name: minbaths, var: minbaths}, {name: maxbaths, var: maxbaths}, {name: minbeds, var: minbeds}, {name: maxbeds, var: maxbeds}, {name: maxdom, var: maxdom}, {name: minyear, var: minyear}, {name: limit, var: limit}, {name: offset, var: offset}, {name: lastId, var: last_id}, {name: vendor, var: vendor}, {name: postalCodes, var: postal_codes, style: multi}, {name: features, var: features, style: multi}, {name: water, var: water}, {name: neighborhoods, var: neighborhoods, style: multi}, {name: cities, var: cities, style: multi}, {name: counties, var: counties, style: multi}, {name: points, var: points, style: multi}, {name: include, var: include, style: multi}, {name: sort, var: sort}, {name: count, var: count}]
    accept: ["application/json", "application/vnd.simplyrets-v0.1+json"]
    ok: [200]
    auth: basic
  } {
    q: $q, status: $status, type: $type, subtype: $subtype, agent: $agent, brokers: $brokers, minprice: $minprice, maxprice: $maxprice, minarea: $minarea, maxarea: $maxarea, minbaths: $minbaths, maxbaths: $maxbaths, minbeds: $minbeds, maxbeds: $maxbeds, maxdom: $maxdom, minyear: $minyear, limit: $limit, offset: $offset, last_id: $last_id, vendor: $vendor, postal_codes: $postal_codes, features: $features, water: $water, neighborhoods: $neighborhoods, cities: $cities, counties: $counties, points: $points, include: $include, sort: $sort, count: $count
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}

# Single Listing Endpoint
#
# GET /properties/{mlsId}
# Returns: record<address: record<city: string, country: string, crossStreet: string, full: string, postalCode: string, state: string, streetName: string, streetNumber: int, streetNumberText: string>, agent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, association: record<amenities: string, fee: int, name: string>, coAgent: record<contact: record<cell: string, email: string, office: string>, firstName: string, id: string, lastName: string>, disclaimer: string, geo: record<county: string, directions: string, lat: float, lng: float, marketArea: string>, leaseTerm: string, leaseType: string, listDate: string, listPrice: float, listingId: string, mls: record<area: string, areaMinor: string, daysOnMarket: int, originatingSystemName: string, status: string, statusText: string>, mlsId: int, modified: string, office: record<brokerid: string, contact: record<cell: string, email: string, office: string>, name: string, servingName: string>, photos: list<string>, privateRemarks: string, property: record<accessibility: string, additionalRooms: string, area: int, areaSource: string, bathsFull: int, bathsHalf: int, bathsThreeQuarter: int, bedrooms: int, construction: string, cooling: string, exteriorFeatures: string, fireplaces: int, flooring: string, foundation: string, garageSpaces: float, heating: string, interiorFeatures: string, laundryFeatures: string, lotDescription: string, lotSize: string, lotSizeAcres: float, lotSizeArea: float, lotSizeAreaUnits: string, maintenanceExpense: float, occupantName: string, occupantType: string, ownerName: string, parking: record<description: string, leased: string, spaces: int>, poolFeatures: string, roof: string, stories: float, style: string, subType: string, subTypeRaw: string, subdivision: string, type: string, view: string, water: string, yearBuilt: int>, remarks: string, sales: record<agent: string, closeDate: string, closePrice: int, contractDate: string, office: string>, school: record<district: string, elementarySchool: string, highSchool: string, middleSchool: string>, showingInstructions: string, tax: record<id: string, taxAnnualAmount: string, taxYear: int>, virtualTourUrl: string>
export def "get-properties-mls-id" [
  mls_id: int
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
  --include: list<string>@include-completer-1 # Include a extra fields which are not in the default response body - 'association' includes additional HOA data - 'agreement' information on the listing agreement - 'garageSpaces' additional garage data - 'maintenanceExpense' data on maintenance expenses - 'parking' additional parking data - 'pool' includes an additional pool description - 'rooms' include parameter will include any additional rooms as a list. Note that your MLS must provide these fields in their RETS data for them to be available with valid data in the API response. If your MLS does not offer these fields, they will contain 'null'. In the future, fields which require an 'include' may become available by default.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/properties/{mlsId}"
    path_params: [{name: mlsId, var: mls_id}]
    query: [{name: include, var: include, style: multi}]
    accept: ["application/json", "application/vnd.simplyrets-v0.1+json"]
    ok: [200]
    auth: basic
  } {
    mls_id: $mls_id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run, accept: $accept
  }
}
