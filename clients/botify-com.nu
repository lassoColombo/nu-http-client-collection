# Auto-generated client for Botify API v1.0.0
# Source: https://api.apis.guru/v2/specs/botify.com/1.0.0/openapi.json
# Auth: --token flag or $env.BOTIFY_API_TOKEN

const CLIENT = {
  base_url: "https://api.botify.com/v1"
  token_env_var: "BOTIFY_API_TOKEN"
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

def base-url-completer [] { ["https://api.botify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def frequency-completer [] { ["1mn" "5mn" "60mn"] }
def list-type-completer [] { ["crawled" "errors"] }
def medium-completer [] { ["organic" "social"] }
def source-completer [] { ["all" "aol" "ask" "baidu" "bing" "facebook" "google" "google+" "linkedin" "naver" "pinterest" "reddit" "tumblr" "twitter" "yahoo" "yandex"] }
def area-completer [] { ["current" "disappeared" "new" "search_engines_orphans"] }
def area-completer-1 [] { ["current" "new"] }
def area-completer-2 [] { ["current" "disappeared" "new"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-project-analyses: "record<count: int, next: string, page: int, previous: string, results: table<config: string, date_created: string, date_finished: string, date_last_modified: string, date_launched: string, features: string, id: int, name: string, slug: string, status: string, url: string, urls_done: string, urls_in_queue: string, user: record>, size: int>"
    get-analysis-summary: "record<config: string, date_finished: string, date_last_modified: string, date_launched: string, failures: string, features: string, id: int, name: string, red_button_domain: string, slug: string, url: string, urls_done: string, urls_in_queue: string, user: record<company_name: string, date_joined: string, email: string, first_name: string, is_organization: string, last_name: string, login: string, status: string, url: string>>"
    get-crawl-statistics: "record<depth_current: int, last_upd_dt: string, pages_dones: int, pages_dones_2xx: int, pages_dones_3xx: int, pages_dones_4xx: int, pages_dones_5xx: int, pages_dones_networkerror: int, pages_dones_xxx: int, pages_known: int>"
    get-crawl-statistics-by-frequency: "record<avg_delay: table<count: int, datetime: string>, avg_size: table<count: int, datetime: string>, frequency: string, http_code_2xx: table<count: int, datetime: string>, http_code_3xx: table<count: int, datetime: string>, http_code_4xx: table<count: int, datetime: string>, http_code_5xx: table<count: int, datetime: string>, http_code_xxx: table<count: int, datetime: string>, last_update_date: string, new_urls: table<count: int, datetime: string>>"
    get-crawl-statistics-urls: "list<any>"
    get-ganalytics-orphan-ur-ls: "record<count: int, next: string, page: int, previous: string, results: table<url: string, visits: int>, size: int>"
    get-links-percentiles: "record<domain: string, percentiles: table<avg: int, id: int, max: int, metric_total: int, min: int, url_total: int>>"
    get-page-rank-lost: "record<external: float, non_crawled: float, robots_txt: float>"
    get-sitemaps-report: "record<count: int, errors: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_indexes: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_only: record<in_configuration: int, out_of_configuration: int>, sitemaps: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>>"
    get-sitemaps-samples-out-of-config: "record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>"
    get-sitemaps-samples-sitemaps-only: "record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>"
    get-links-top-domains: "record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>"
    get-links-top-subdomains: "record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>"
    get-urls: "record<count: int, next: string, page: int, previous: string, results: list<record>, size: int>"
    get-urls-aggs: "list<any>"
    get-urls-datamodel: "record<fields: table<group: string, id: string, multiple: bool, name: string, permissions: list, subtype: string, type: string>, groups: table<id: string, name: string>>"
    get-urls-exports: "record<count: int, next: string, page: int, previous: string, results: table<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record, results: string>, size: int>"
    create-urls-export: "record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>"
    get-urls-export-status: "record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>"
    get-urls-suggested-filters: "record<aggs: list<record>, filters: record>"
    get-url-detail: "record"
    get-user-projects: "record<count: int, next: string, page: int, previous: string, results: table<active: bool, current_settings: record, date_created: string, name: string, slug: string, user: record>, size: int>"
    test-url-rewriting-rules: "record<rules: table<ignore_case: bool, regex: string, replace: string>, urls: list<string>>"
    get-saved-filters: "record<count: int, next: string, page: int, previous: string, results: table<filters: record, identifier: string, name: string>, size: int>"
    get-saved-filter: "record<filters: record, identifier: string, name: string>"
    get-project-urls-aggs: "record"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-project-analyses" "get-analysis-summary" "get-crawl-statistics" "get-crawl-statistics-by-frequency" "get-crawl-statistics-urls" "get-ganalytics-orphan-ur-ls" "get-links-percentiles" "get-page-rank-lost" "get-sitemaps-report" "get-sitemaps-samples-out-of-config" "get-sitemaps-samples-sitemaps-only" "get-links-top-domains" "get-links-top-subdomains" "get-urls" "get-urls-aggs" "get-urls-datamodel" "get-urls-exports" "create-urls-export" "get-urls-export-status" "get-urls-suggested-filters" "get-url-detail" "get-user-projects" "test-url-rewriting-rules" "get-saved-filters" "get-saved-filter" "get-project-urls-aggs" "commands"] | sort) } | get name | first)
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

# List all analyses for a project
#
# GET /analyses/{username}/{project_slug}
# Returns: record<count: int, next: string, page: int, previous: string, results: table<config: string, date_created: string, date_finished: string, date_last_modified: string, date_launched: string, features: string, id: int, name: string, slug: string, status: string, url: string, urls_done: string, urls_in_queue: string, user: record>, size: int>
# operationId: getProjectAnalyses
export def "get-project-analyses" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an Analysis detail
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}
# Returns: record<config: string, date_finished: string, date_last_modified: string, date_launched: string, failures: string, features: string, id: int, name: string, red_button_domain: string, slug: string, url: string, urls_done: string, urls_in_queue: string, user: record<company_name: string, date_joined: string, email: string, first_name: string, is_organization: string, last_name: string, login: string, status: string, url: string>>
# operationId: getAnalysisSummary
export def "get-analysis-summary" [
  username: string
  project_slug: string
  analysis_slug: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return global statistics for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics
# Returns: record<depth_current: int, last_upd_dt: string, pages_dones: int, pages_dones_2xx: int, pages_dones_3xx: int, pages_dones_4xx: int, pages_dones_5xx: int, pages_dones_networkerror: int, pages_dones_xxx: int, pages_known: int>
# operationId: getCrawlStatistics
export def "get-crawl-statistics" [
  username: string
  project_slug: string
  analysis_slug: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return crawl statistics grouped by time frequency (1 min, 5 mins or 60 min)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time
# Returns: record<avg_delay: table<count: int, datetime: string>, avg_size: table<count: int, datetime: string>, frequency: string, http_code_2xx: table<count: int, datetime: string>, http_code_3xx: table<count: int, datetime: string>, http_code_4xx: table<count: int, datetime: string>, http_code_5xx: table<count: int, datetime: string>, http_code_xxx: table<count: int, datetime: string>, last_update_date: string, new_urls: table<count: int, datetime: string>>
# operationId: getCrawlStatisticsByFrequency
export def "get-crawl-statistics-by-frequency" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # max number of elements to retrieve (format: int32)
  --frequency: string@frequency-completer # Aggregation frequency (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: limit, var: limit}, {name: frequency, var: frequency, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, limit: $limit, frequency: $frequency
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return a list of 1000 latest URLs crawled (all crawled URLs or only URLS with HTTP errors)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}
# Returns: list<any>
# operationId: getCrawlStatisticsUrls
export def "get-crawl-statistics-urls" [
  username: string
  project_slug: string
  analysis_slug: string
  list_type: string@list-type-completer
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}, {name: list_type, var: list_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, list_type: $list_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List of Orphan URLs
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}
# Returns: record<count: int, next: string, page: int, previous: string, results: table<url: string, visits: int>, size: int>
# operationId: getGanalyticsOrphanURLs
export def "get-ganalytics-orphan-ur-ls" [
  username: string
  project_slug: string
  analysis_slug: string
  medium: string@medium-completer
  source: string@source-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}, {name: medium, var: medium}, {name: source, var: source}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, medium: $medium, source: $source, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get inlinks percentiles
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles
# Returns: record<domain: string, percentiles: table<avg: int, id: int, max: int, metric_total: int, min: int, url_total: int>>
# operationId: getLinksPercentiles
export def "get-links-percentiles" [
  username: string
  project_slug: string
  analysis_slug: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lost pagerank
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost
# Returns: record<external: float, non_crawled: float, robots_txt: float>
# operationId: getPageRankLost
export def "get-page-rank-lost" [
  username: string
  project_slug: string
  analysis_slug: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get global information of the sitemaps found (sitemaps indexes, invalid sitemaps urls, etc
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report
# Returns: record<count: int, errors: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_indexes: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_only: record<in_configuration: int, out_of_configuration: int>, sitemaps: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>>
# operationId: getSitemapsReport
export def "get-sitemaps-report" [
  username: string
  project_slug: string
  analysis_slug: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sample list of URLs which were found in your sitemaps but outside of the
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config
# Returns: record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>
# operationId: getSitemapsSamplesOutOfConfig
export def "get-sitemaps-samples-out-of-config" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sample list of URLs which were found in your sitemaps, within the project
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only
# Returns: record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>
# operationId: getSitemapsSamplesSitemapsOnly
export def "get-sitemaps-samples-sitemaps-only" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top domains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains
# Returns: record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>
# operationId: getLinksTopDomains
export def "get-links-top-domains" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Top subddomains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains
# Returns: record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>
# operationId: getLinksTopSubdomains
export def "get-links-top-subdomains" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Executes a query and returns a paginated response
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls
# Returns: record<count: int, next: string, page: int, previous: string, results: list<record>, size: int>
# operationId: getUrls
export def "get-urls" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # Analysis context to execute the query (default: current)
  --page: int # Page Number (format: int32)
  --size: int # Page Size (format: int32)
  --fields: list<string>
  --filters: record
  --sort: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: area, var: area}, {name: page, var: page}, {name: size, var: size}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}, {name: filters, var: filters}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, area: $area, page: $page, size: $size, fields: $fields, filters: $filters, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Query aggregator
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs
# Returns: list<any>
# operationId: getUrlsAggs
export def "get-urls-aggs" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --body: list
]: any -> oneof<list<any>, record, string, nothing> {
  $in | http-request {
    method: post
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: area, var: area}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, area: $area, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets an Analysis datamodel
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel
# Returns: record<fields: table<group: string, id: string, multiple: bool, name: string, permissions: list, subtype: string, type: string>, groups: table<id: string, name: string>>
# operationId: getUrlsDatamodel
export def "get-urls-datamodel" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: area, var: area}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, area: $area
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# A list of the CSV Exports requests and their current status
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# Returns: record<count: int, next: string, page: int, previous: string, results: table<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record, results: string>, size: int>
# operationId: getUrlsExports
export def "get-urls-exports" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new UrlExport object and starts a task that will export the results into a csv
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# Returns: record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>
# operationId: createUrlsExport
export def "create-urls-export" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --fields: list<string>
  --filters: record
  --sort: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: area, var: area}]
    body: {content_type: "application/json", kind: json, fields: [{name: fields, var: fields}, {name: filters, var: filters}, {name: sort, var: sort}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, area: $area, fields: $fields, filters: $filters, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Checks the status of an CSVUrlExportJob object
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}
# Returns: record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>
# operationId: getUrlsExportStatus
export def "get-urls-export-status" [
  username: string
  project_slug: string
  analysis_slug: string
  url_export_id: string
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
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}, {name: url_export_id, var: url_export_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, url_export_id: $url_export_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Return most frequent segments (= suggested patterns in the previous version)
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters
# Returns: record<aggs: list<record>, filters: record>
# operationId: getUrlsSuggestedFilters
export def "get-urls-suggested-filters" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-1 # default: current
  --aggs: list
  --filters: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}]
    query: [{name: area, var: area}]
    body: {content_type: "application/json", kind: json, fields: [{name: aggs, var: aggs}, {name: filters, var: filters}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, area: $area, aggs: $aggs, filters: $filters
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets the detail of an URL for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}
# Returns: record
# operationId: getUrlDetail
export def "get-url-detail" [
  username: string
  project_slug: string
  analysis_slug: string
  url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # comma separated list of fields to return (c.f. URLs Datamodel)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: analysis_slug, var: analysis_slug}, {name: url, var: url}]
    query: [{name: fields, var: fields, style: csv}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, analysis_slug: $analysis_slug, url: $url, fields: $fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all active projects for the user
#
# GET /projects/{username}
# Returns: record<count: int, next: string, page: int, previous: string, results: table<active: bool, current_settings: record, date_created: string, name: string, slug: string, user: record>, size: int>
# operationId: getUserProjects
export def "get-user-projects" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{username}"
    path_params: [{name: username, var: username}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Match and replace parts of a URL based on rules passed in POST data
#
# POST /projects/{username}/{project_slug}/features/url_rewriting/rules_validator
# Returns: record<rules: table<ignore_case: bool, regex: string, replace: string>, urls: list<string>>
# operationId: testUrlRewritingRules
export def "test-url-rewriting-rules" [
  username: string
  project_slug: string
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
    path: "/projects/{username}/{project_slug}/features/url_rewriting/rules_validator"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}]
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all the project's saved filters (each filter's name, ID and filter value)
#
# GET /projects/{username}/{project_slug}/filters
# Returns: record<count: int, next: string, page: int, previous: string, results: table<filters: record, identifier: string, name: string>, size: int>
# operationId: getSavedFilters
export def "get-saved-filters" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/projects/{username}/{project_slug}/filters"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}]
    query: [{name: page, var: page}, {name: size, var: size}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, page: $page, size: $size
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retrieves a specific saved filter's name, ID and filter value
#
# GET /projects/{username}/{project_slug}/filters/{identifier}
# Returns: record<filters: record, identifier: string, name: string>
# operationId: getSavedFilter
export def "get-saved-filter" [
  username: string
  project_slug: string
  identifier: string
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
    path: "/projects/{username}/{project_slug}/filters/{identifier}"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}, {name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Project Query aggregator
#
# POST /projects/{username}/{project_slug}/urls/aggs
# Returns: record
# operationId: getProjectUrlsAggs
export def "get-project-urls-aggs" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-2 # Analysis context to execute the queries (default: current)
  --last-analysis-slug: string # Last analysis on the trend
  --nb-analyses: int # Max number of analysis to return (format: int32, default: 20)
  --body: list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/projects/{username}/{project_slug}/urls/aggs"
    path_params: [{name: username, var: username}, {name: project_slug, var: project_slug}]
    query: [{name: area, var: area}, {name: last_analysis_slug, var: last_analysis_slug}, {name: nb_analyses, var: nb_analyses}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    username: $username, project_slug: $project_slug, area: $area, last_analysis_slug: $last_analysis_slug, nb_analyses: $nb_analyses, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
