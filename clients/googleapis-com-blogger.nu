# Auto-generated client for Blogger API v3
# Source: https://api.apis.guru/v2/specs/googleapis.com/blogger/v3/openapi.json
# Auth: --token flag or $env.BLOGGER_API_TOKEN

const CLIENT = {
  base_url: "https://blogger.googleapis.com"
  token_env_var: "BLOGGER_API_TOKEN"
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

def base-url-completer [] { ["https://blogger.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def view-completer [] { ["ADMIN" "AUTHOR" "READER" "VIEW_TYPE_UNSPECIFIED"] }
def status-completer [] { ["DRAFT" "LIVE" "SOFT_TRASHED"] }
def order-by-completer [] { ["ORDER_BY_UNSPECIFIED" "PUBLISHED" "UPDATED"] }
def sort-option-completer [] { ["ASCENDING" "DESCENDING" "SORT_OPTION_UNSPECIFIED"] }
def reader-comments-completer [] { ["ALLOW" "DONT_ALLOW_HIDE_EXISTING" "DONT_ALLOW_SHOW_EXISTING"] }
def status-completer-1 [] { ["DRAFT" "LIVE" "SCHEDULED" "SOFT_TRASHED"] }
def status-completer-2 [] { ["EMPTIED" "LIVE" "PENDING" "SPAM"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    blogger-blogs-get-by-url: "record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list<record>, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>"
    blogger-blogs-get: "record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list<record>, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>"
    blogger-comments-list-by-blog: "record<etag: string, items: table<author: record, blog: record, content: string, id: string, inReplyTo: record, kind: string, post: record, published: string, selfLink: string, status: string, updated: string>, kind: string, nextPageToken: string, prevPageToken: string>"
    blogger-pages-list: "record<etag: string, items: table<author: record, blog: record, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string>"
    blogger-pages-insert: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-pages-get: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-pages-patch: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-pages-update: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-pages-publish: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-pages-revert: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>"
    blogger-page-views-get: "record<blogId: string, counts: table<count: string, timeRange: string>, kind: string>"
    blogger-posts-list: "record<etag: string, items: table<author: record, blog: record, content: string, customMetaData: string, etag: string, id: string, images: list, kind: string, labels: list, location: record, published: string, readerComments: string, replies: record, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string, prevPageToken: string>"
    blogger-posts-insert: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-posts-get-by-path: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-posts-search: "record<etag: string, items: table<author: record, blog: record, content: string, customMetaData: string, etag: string, id: string, images: list, kind: string, labels: list, location: record, published: string, readerComments: string, replies: record, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string, prevPageToken: string>"
    blogger-posts-get: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-posts-patch: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-posts-update: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-comments-list: "record<etag: string, items: table<author: record, blog: record, content: string, id: string, inReplyTo: record, kind: string, post: record, published: string, selfLink: string, status: string, updated: string>, kind: string, nextPageToken: string, prevPageToken: string>"
    blogger-comments-get: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>"
    blogger-comments-approve: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>"
    blogger-comments-remove-content: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>"
    blogger-comments-mark-as-spam: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>"
    blogger-posts-publish: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-posts-revert: "record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>"
    blogger-users-get: "record<about: string, blogs: record<selfLink: string>, created: string, displayName: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, selfLink: string, url: string>"
    blogger-blogs-list-by-user: "record<blogUserInfos: table<blog: record, blog_user_info: record, kind: string>, items: table<customMetaData: string, description: string, id: string, kind: string, locale: record, name: string, pages: record, posts: record, published: string, selfLink: string, status: string, updated: string, url: string>, kind: string>"
    blogger-blog-user-infos-get: "record<blog: record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>, blog_user_info: record<blogId: string, hasAdminAccess: bool, kind: string, photosAlbumKey: string, role: string, userId: string>, kind: string>"
    blogger-post-user-infos-list: "record<items: table<kind: string, post: record, post_user_info: record>, kind: string, nextPageToken: string>"
    blogger-post-user-infos-get: "record<kind: string, post: record<author: record<displayName: string, id: string, image: record, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: list<record>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, post_user_info: record<blogId: string, hasEditAccess: bool, kind: string, postId: string, userId: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["blogger-blogs-get-by-url" "blogger-blogs-get" "blogger-comments-list-by-blog" "blogger-pages-list" "blogger-pages-insert" "blogger-pages-delete" "blogger-pages-get" "blogger-pages-patch" "blogger-pages-update" "blogger-pages-publish" "blogger-pages-revert" "blogger-page-views-get" "blogger-posts-list" "blogger-posts-insert" "blogger-posts-get-by-path" "blogger-posts-search" "blogger-posts-delete" "blogger-posts-get" "blogger-posts-patch" "blogger-posts-update" "blogger-comments-list" "blogger-comments-delete" "blogger-comments-get" "blogger-comments-approve" "blogger-comments-remove-content" "blogger-comments-mark-as-spam" "blogger-posts-publish" "blogger-posts-revert" "blogger-users-get" "blogger-blogs-list-by-user" "blogger-blog-user-infos-get" "blogger-post-user-infos-list" "blogger-post-user-infos-get" "commands"] | sort) } | get name | first)
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

# Gets a blog by url.
#
# GET /v3/blogs/byurl
# Returns: record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list<record>, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>
# operationId: blogger.blogs.getByUrl
export def "blogger-blogs-get-by-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --url: string # required
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/byurl"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: url, var: url, required: true}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, url: $url, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a blog by id.
#
# GET /v3/blogs/{blogId}
# Returns: record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list<record>, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>
# operationId: blogger.blogs.get
export def "blogger-blogs-get" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-posts: int
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxPosts, var: max_posts}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_posts: $max_posts, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists comments by blog.
#
# GET /v3/blogs/{blogId}/comments
# Returns: record<etag: string, items: table<author: record, blog: record, content: string, id: string, inReplyTo: record, kind: string, post: record, published: string, selfLink: string, status: string, updated: string>, kind: string, nextPageToken: string, prevPageToken: string>
# operationId: blogger.comments.listByBlog
export def "blogger-comments-list-by-blog" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string
  --fetch-bodies: oneof<nothing, bool>
  --max-results: int
  --page-token: string
  --start-date: string
  --status: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/comments"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: fetchBodies, var: fetch_bodies}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: startDate, var: start_date}, {name: status, var: status, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, fetch_bodies: $fetch_bodies, max_results: $max_results, page_token: $page_token, start_date: $start_date, status: $status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists pages.
#
# GET /v3/blogs/{blogId}/pages
# Returns: record<etag: string, items: table<author: record, blog: record, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string>
# operationId: blogger.pages.list
export def "blogger-pages-list" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-bodies: oneof<nothing, bool>
  --max-results: int
  --page-token: string
  --status: list<string>
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/pages"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchBodies, var: fetch_bodies}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: status, var: status, style: multi}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_bodies: $fetch_bodies, max_results: $max_results, page_token: $page_token, status: $status, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a page.
#
# POST /v3/blogs/{blogId}/pages
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.insert
export def "blogger-pages-insert" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --is-draft: oneof<nothing, bool>
  --author: record # The author of this Page. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Page. — shape: {id?: string}
  --content: string # The body content of this Page, in HTML.
  --etag: string # Etag of the resource.
  --id: string # The identifier for this resource.
  --kind: string # The kind of this entity. Always blogger#page.
  --published: string # RFC 3339 date-time when this Page was published.
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer # The status of the page for admin resources (either LIVE or DRAFT).
  --title: string # The title of this entity. This is the name displayed in the Admin user interface.
  --trashed: string # RFC 3339 date-time when this Page was trashed.
  --updated: string # RFC 3339 date-time when this Page was last updated.
  --url: string # The URL that this Page is displayed at.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/blogs/{blogId}/pages"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: isDraft, var: is_draft}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: published, var: published}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, is_draft: $is_draft, author: $author, blog: $blog, content: $content, etag: $etag, id: $id, kind: $kind, published: $published, self_link: $self_link, status: $status, title: $title, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a page by blog id and page id.
#
# DELETE /v3/blogs/{blogId}/pages/{pageId}
# operationId: blogger.pages.delete
export def "blogger-pages-delete" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --use-trash: oneof<nothing, bool> # Move to Trash if possible
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/blogs/{blogId}/pages/{pageId}"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: useTrash, var: use_trash}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, use_trash: $use_trash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a page by blog id and page id.
#
# GET /v3/blogs/{blogId}/pages/{pageId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.get
export def "blogger-pages-get" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/pages/{pageId}"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a page.
#
# PATCH /v3/blogs/{blogId}/pages/{pageId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.patch
export def "blogger-pages-patch" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --publish: oneof<nothing, bool>
  --revert: oneof<nothing, bool>
  --author: record # The author of this Page. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Page. — shape: {id?: string}
  --content: string # The body content of this Page, in HTML.
  --etag: string # Etag of the resource.
  --id: string # The identifier for this resource.
  --kind: string # The kind of this entity. Always blogger#page.
  --published: string # RFC 3339 date-time when this Page was published.
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer # The status of the page for admin resources (either LIVE or DRAFT).
  --title: string # The title of this entity. This is the name displayed in the Admin user interface.
  --trashed: string # RFC 3339 date-time when this Page was trashed.
  --updated: string # RFC 3339 date-time when this Page was last updated.
  --url: string # The URL that this Page is displayed at.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v3/blogs/{blogId}/pages/{pageId}"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: publish, var: publish}, {name: revert, var: revert}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: published, var: published}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, publish: $publish, revert: $revert, author: $author, blog: $blog, content: $content, etag: $etag, id: $id, kind: $kind, published: $published, self_link: $self_link, status: $status, title: $title, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a page by blog id and page id.
#
# PUT /v3/blogs/{blogId}/pages/{pageId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.update
export def "blogger-pages-update" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --publish: oneof<nothing, bool>
  --revert: oneof<nothing, bool>
  --author: record # The author of this Page. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Page. — shape: {id?: string}
  --content: string # The body content of this Page, in HTML.
  --etag: string # Etag of the resource.
  --id: string # The identifier for this resource.
  --kind: string # The kind of this entity. Always blogger#page.
  --published: string # RFC 3339 date-time when this Page was published.
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer # The status of the page for admin resources (either LIVE or DRAFT).
  --title: string # The title of this entity. This is the name displayed in the Admin user interface.
  --trashed: string # RFC 3339 date-time when this Page was trashed.
  --updated: string # RFC 3339 date-time when this Page was last updated.
  --url: string # The URL that this Page is displayed at.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/blogs/{blogId}/pages/{pageId}"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: publish, var: publish}, {name: revert, var: revert}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: etag, var: etag}, {name: id, var: id}, {name: kind, var: kind}, {name: published, var: published}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, publish: $publish, revert: $revert, author: $author, blog: $blog, content: $content, etag: $etag, id: $id, kind: $kind, published: $published, self_link: $self_link, status: $status, title: $title, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a page.
#
# POST /v3/blogs/{blogId}/pages/{pageId}/publish
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.publish
export def "blogger-pages-publish" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/pages/{pageId}/publish"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverts a published or scheduled page to draft state.
#
# POST /v3/blogs/{blogId}/pages/{pageId}/revert
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, etag: string, id: string, kind: string, published: string, selfLink: string, status: string, title: string, trashed: string, updated: string, url: string>
# operationId: blogger.pages.revert
export def "blogger-pages-revert" [
  blog_id: string
  page_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/pages/{pageId}/revert"
    path_params: [{name: blogId, var: blog_id}, {name: pageId, var: page_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, page_id: $page_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets page views by blog id.
#
# GET /v3/blogs/{blogId}/pageviews
# Returns: record<blogId: string, counts: table<count: string, timeRange: string>, kind: string>
# operationId: blogger.pageViews.get
export def "blogger-page-views-get" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --range: list<string>
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/pageviews"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: range, var: range, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, range: $range
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists posts.
#
# GET /v3/blogs/{blogId}/posts
# Returns: record<etag: string, items: table<author: record, blog: record, content: string, customMetaData: string, etag: string, id: string, images: list, kind: string, labels: list, location: record, published: string, readerComments: string, replies: record, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string, prevPageToken: string>
# operationId: blogger.posts.list
export def "blogger-posts-list" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string
  --fetch-bodies: oneof<nothing, bool>
  --fetch-images: oneof<nothing, bool>
  --labels: string
  --max-results: int
  --order-by: string@order-by-completer
  --page-token: string
  --sort-option: string@sort-option-completer # Sort direction applied to post list.
  --start-date: string
  --status: list<string>
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: fetchBodies, var: fetch_bodies}, {name: fetchImages, var: fetch_images}, {name: labels, var: labels}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: sortOption, var: sort_option}, {name: startDate, var: start_date}, {name: status, var: status, style: multi}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, fetch_bodies: $fetch_bodies, fetch_images: $fetch_images, labels: $labels, max_results: $max_results, order_by: $order_by, page_token: $page_token, sort_option: $sort_option, start_date: $start_date, status: $status, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Inserts a post.
#
# POST /v3/blogs/{blogId}/posts
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.insert
export def "blogger-posts-insert" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-body: oneof<nothing, bool>
  --fetch-images: oneof<nothing, bool>
  --is-draft: oneof<nothing, bool>
  --author: record # The author of this Post. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Post. — shape: {id?: string}
  --content: string # The content of the Post. May contain HTML markup.
  --custom-meta-data: string # The JSON meta-data for the Post.
  --etag: string # Etag of the resource.
  --id: string # The identifier of this Post.
  --images: list # Display image for the Post. — item shape: {url?: string}
  --kind: string # The kind of this entity. Always blogger#post.
  --labels: list<string> # The list of labels this Post was tagged with.
  --location: record # The location for geotagged posts. — shape: {lat?: float, lng?: float, name?: string, span?: string}
  --published: string # RFC 3339 date-time when this Post was published.
  --reader-comments: string@reader-comments-completer # Comment control and display setting for readers of this post.
  --replies: record # The container of comments on this Post. — shape: {items?: list, selfLink?: string, totalItems?: string}
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer-1 # Status of the post. Only set for admin-level requests.
  --title: string # The title of the Post.
  --title-link: string # The title link URL, similar to atom's related link.
  --trashed: string # RFC 3339 date-time when this Post was last trashed.
  --updated: string # RFC 3339 date-time when this Post was last updated.
  --url: string # The URL where this Post is displayed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchBody, var: fetch_body}, {name: fetchImages, var: fetch_images}, {name: isDraft, var: is_draft}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: customMetaData, var: custom_meta_data}, {name: etag, var: etag}, {name: id, var: id}, {name: images, var: images}, {name: kind, var: kind}, {name: labels, var: labels}, {name: location, var: location}, {name: published, var: published}, {name: readerComments, var: reader_comments}, {name: replies, var: replies}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: titleLink, var: title_link}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_body: $fetch_body, fetch_images: $fetch_images, is_draft: $is_draft, author: $author, blog: $blog, content: $content, custom_meta_data: $custom_meta_data, etag: $etag, id: $id, images: $images, kind: $kind, labels: $labels, location: $location, published: $published, reader_comments: $reader_comments, replies: $replies, self_link: $self_link, status: $status, title: $title, title_link: $title_link, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a post by path.
#
# GET /v3/blogs/{blogId}/posts/bypath
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.getByPath
export def "blogger-posts-get-by-path" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --path: string # required
  --max-comments: int
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts/bypath"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: path, var: path, required: true}, {name: maxComments, var: max_comments}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, path: $path, max_comments: $max_comments, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for posts matching given query terms in the specified blog.
#
# GET /v3/blogs/{blogId}/posts/search
# Returns: record<etag: string, items: table<author: record, blog: record, content: string, customMetaData: string, etag: string, id: string, images: list, kind: string, labels: list, location: record, published: string, readerComments: string, replies: record, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, kind: string, nextPageToken: string, prevPageToken: string>
# operationId: blogger.posts.search
export def "blogger-posts-search" [
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --q: string # required
  --fetch-bodies: oneof<nothing, bool>
  --order-by: string@order-by-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts/search"
    path_params: [{name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: q, var: q, required: true}, {name: fetchBodies, var: fetch_bodies}, {name: orderBy, var: order_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, q: $q, fetch_bodies: $fetch_bodies, order_by: $order_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a post by blog id and post id.
#
# DELETE /v3/blogs/{blogId}/posts/{postId}
# operationId: blogger.posts.delete
export def "blogger-posts-delete" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --use-trash: oneof<nothing, bool> # Move to Trash if possible
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/blogs/{blogId}/posts/{postId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: useTrash, var: use_trash}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, use_trash: $use_trash
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a post by blog id and post id
#
# GET /v3/blogs/{blogId}/posts/{postId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.get
export def "blogger-posts-get" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-body: oneof<nothing, bool>
  --fetch-images: oneof<nothing, bool>
  --max-comments: int
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts/{postId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchBody, var: fetch_body}, {name: fetchImages, var: fetch_images}, {name: maxComments, var: max_comments}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_body: $fetch_body, fetch_images: $fetch_images, max_comments: $max_comments, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patches a post.
#
# PATCH /v3/blogs/{blogId}/posts/{postId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.patch
export def "blogger-posts-patch" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-body: oneof<nothing, bool>
  --fetch-images: oneof<nothing, bool>
  --max-comments: int
  --publish: oneof<nothing, bool>
  --revert: oneof<nothing, bool>
  --author: record # The author of this Post. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Post. — shape: {id?: string}
  --content: string # The content of the Post. May contain HTML markup.
  --custom-meta-data: string # The JSON meta-data for the Post.
  --etag: string # Etag of the resource.
  --id: string # The identifier of this Post.
  --images: list # Display image for the Post. — item shape: {url?: string}
  --kind: string # The kind of this entity. Always blogger#post.
  --labels: list<string> # The list of labels this Post was tagged with.
  --location: record # The location for geotagged posts. — shape: {lat?: float, lng?: float, name?: string, span?: string}
  --published: string # RFC 3339 date-time when this Post was published.
  --reader-comments: string@reader-comments-completer # Comment control and display setting for readers of this post.
  --replies: record # The container of comments on this Post. — shape: {items?: list, selfLink?: string, totalItems?: string}
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer-1 # Status of the post. Only set for admin-level requests.
  --title: string # The title of the Post.
  --title-link: string # The title link URL, similar to atom's related link.
  --trashed: string # RFC 3339 date-time when this Post was last trashed.
  --updated: string # RFC 3339 date-time when this Post was last updated.
  --url: string # The URL where this Post is displayed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v3/blogs/{blogId}/posts/{postId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchBody, var: fetch_body}, {name: fetchImages, var: fetch_images}, {name: maxComments, var: max_comments}, {name: publish, var: publish}, {name: revert, var: revert}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: customMetaData, var: custom_meta_data}, {name: etag, var: etag}, {name: id, var: id}, {name: images, var: images}, {name: kind, var: kind}, {name: labels, var: labels}, {name: location, var: location}, {name: published, var: published}, {name: readerComments, var: reader_comments}, {name: replies, var: replies}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: titleLink, var: title_link}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_body: $fetch_body, fetch_images: $fetch_images, max_comments: $max_comments, publish: $publish, revert: $revert, author: $author, blog: $blog, content: $content, custom_meta_data: $custom_meta_data, etag: $etag, id: $id, images: $images, kind: $kind, labels: $labels, location: $location, published: $published, reader_comments: $reader_comments, replies: $replies, self_link: $self_link, status: $status, title: $title, title_link: $title_link, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a post by blog id and post id.
#
# PUT /v3/blogs/{blogId}/posts/{postId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.update
export def "blogger-posts-update" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-body: oneof<nothing, bool>
  --fetch-images: oneof<nothing, bool>
  --max-comments: int
  --publish: oneof<nothing, bool>
  --revert: oneof<nothing, bool>
  --author: record # The author of this Post. — shape: {displayName?: string, id?: string, image?: record, url?: string}
  --blog: record # Data about the blog containing this Post. — shape: {id?: string}
  --content: string # The content of the Post. May contain HTML markup.
  --custom-meta-data: string # The JSON meta-data for the Post.
  --etag: string # Etag of the resource.
  --id: string # The identifier of this Post.
  --images: list # Display image for the Post. — item shape: {url?: string}
  --kind: string # The kind of this entity. Always blogger#post.
  --labels: list<string> # The list of labels this Post was tagged with.
  --location: record # The location for geotagged posts. — shape: {lat?: float, lng?: float, name?: string, span?: string}
  --published: string # RFC 3339 date-time when this Post was published.
  --reader-comments: string@reader-comments-completer # Comment control and display setting for readers of this post.
  --replies: record # The container of comments on this Post. — shape: {items?: list, selfLink?: string, totalItems?: string}
  --self-link: string # The API REST URL to fetch this resource from.
  --status: string@status-completer-1 # Status of the post. Only set for admin-level requests.
  --title: string # The title of the Post.
  --title-link: string # The title link URL, similar to atom's related link.
  --trashed: string # RFC 3339 date-time when this Post was last trashed.
  --updated: string # RFC 3339 date-time when this Post was last updated.
  --url: string # The URL where this Post is displayed.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/blogs/{blogId}/posts/{postId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchBody, var: fetch_body}, {name: fetchImages, var: fetch_images}, {name: maxComments, var: max_comments}, {name: publish, var: publish}, {name: revert, var: revert}]
    body: {content_type: "application/json", kind: json, fields: [{name: author, var: author}, {name: blog, var: blog}, {name: content, var: content}, {name: customMetaData, var: custom_meta_data}, {name: etag, var: etag}, {name: id, var: id}, {name: images, var: images}, {name: kind, var: kind}, {name: labels, var: labels}, {name: location, var: location}, {name: published, var: published}, {name: readerComments, var: reader_comments}, {name: replies, var: replies}, {name: selfLink, var: self_link}, {name: status, var: status}, {name: title, var: title}, {name: titleLink, var: title_link}, {name: trashed, var: trashed}, {name: updated, var: updated}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_body: $fetch_body, fetch_images: $fetch_images, max_comments: $max_comments, publish: $publish, revert: $revert, author: $author, blog: $blog, content: $content, custom_meta_data: $custom_meta_data, etag: $etag, id: $id, images: $images, kind: $kind, labels: $labels, location: $location, published: $published, reader_comments: $reader_comments, replies: $replies, self_link: $self_link, status: $status, title: $title, title_link: $title_link, trashed: $trashed, updated: $updated, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists comments.
#
# GET /v3/blogs/{blogId}/posts/{postId}/comments
# Returns: record<etag: string, items: table<author: record, blog: record, content: string, id: string, inReplyTo: record, kind: string, post: record, published: string, selfLink: string, status: string, updated: string>, kind: string, nextPageToken: string, prevPageToken: string>
# operationId: blogger.comments.list
export def "blogger-comments-list" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string
  --fetch-bodies: oneof<nothing, bool>
  --max-results: int
  --page-token: string
  --start-date: string
  --status: string@status-completer-2
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts/{postId}/comments"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: fetchBodies, var: fetch_bodies}, {name: maxResults, var: max_results}, {name: pageToken, var: page_token}, {name: startDate, var: start_date}, {name: status, var: status}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, fetch_bodies: $fetch_bodies, max_results: $max_results, page_token: $page_token, start_date: $start_date, status: $status, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a comment by blog id, post id and comment id.
#
# DELETE /v3/blogs/{blogId}/posts/{postId}/comments/{commentId}
# operationId: blogger.comments.delete
export def "blogger-comments-delete" [
  blog_id: string
  post_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/blogs/{blogId}/posts/{postId}/comments/{commentId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}, {name: commentId, var: comment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, comment_id: $comment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a comment by id.
#
# GET /v3/blogs/{blogId}/posts/{postId}/comments/{commentId}
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>
# operationId: blogger.comments.get
export def "blogger-comments-get" [
  blog_id: string
  post_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/blogs/{blogId}/posts/{postId}/comments/{commentId}"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}, {name: commentId, var: comment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, comment_id: $comment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks a comment as not spam by blog id, post id and comment id.
#
# POST /v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/approve
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>
# operationId: blogger.comments.approve
export def "blogger-comments-approve" [
  blog_id: string
  post_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/approve"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}, {name: commentId, var: comment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, comment_id: $comment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes the content of a comment by blog id, post id and comment id.
#
# POST /v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/removecontent
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>
# operationId: blogger.comments.removeContent
export def "blogger-comments-remove-content" [
  blog_id: string
  post_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/removecontent"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}, {name: commentId, var: comment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, comment_id: $comment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Marks a comment as spam by blog id, post id and comment id.
#
# POST /v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/spam
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, id: string, inReplyTo: record<id: string>, kind: string, post: record<id: string>, published: string, selfLink: string, status: string, updated: string>
# operationId: blogger.comments.markAsSpam
export def "blogger-comments-mark-as-spam" [
  blog_id: string
  post_id: string
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts/{postId}/comments/{commentId}/spam"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}, {name: commentId, var: comment_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, comment_id: $comment_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Publishes a post.
#
# POST /v3/blogs/{blogId}/posts/{postId}/publish
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.publish
export def "blogger-posts-publish" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --publish-date: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts/{postId}/publish"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: publishDate, var: publish_date}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, publish_date: $publish_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reverts a published or scheduled post to draft state.
#
# POST /v3/blogs/{blogId}/posts/{postId}/revert
# Returns: record<author: record<displayName: string, id: string, image: record<url: string>, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: table<url: string>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list<record>, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>
# operationId: blogger.posts.revert
export def "blogger-posts-revert" [
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/blogs/{blogId}/posts/{postId}/revert"
    path_params: [{name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets one user by user_id.
#
# GET /v3/users/{userId}
# Returns: record<about: string, blogs: record<selfLink: string>, created: string, displayName: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, selfLink: string, url: string>
# operationId: blogger.users.get
export def "blogger-users-get" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{userId}"
    path_params: [{name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists blogs by user.
#
# GET /v3/users/{userId}/blogs
# Returns: record<blogUserInfos: table<blog: record, blog_user_info: record, kind: string>, items: table<customMetaData: string, description: string, id: string, kind: string, locale: record, name: string, pages: record, posts: record, published: string, selfLink: string, status: string, updated: string, url: string>, kind: string>
# operationId: blogger.blogs.listByUser
export def "blogger-blogs-list-by-user" [
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fetch-user-info: oneof<nothing, bool>
  --role: list<string>
  --status: list<string> # Default value of status is LIVE.
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{userId}/blogs"
    path_params: [{name: userId, var: user_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: fetchUserInfo, var: fetch_user_info}, {name: role, var: role, style: multi}, {name: status, var: status, style: multi}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, fetch_user_info: $fetch_user_info, role: $role, status: $status, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets one blog and user info pair by blog id and user id.
#
# GET /v3/users/{userId}/blogs/{blogId}
# Returns: record<blog: record<customMetaData: string, description: string, id: string, kind: string, locale: record<country: string, language: string, variant: string>, name: string, pages: record<selfLink: string, totalItems: int>, posts: record<items: list, selfLink: string, totalItems: int>, published: string, selfLink: string, status: string, updated: string, url: string>, blog_user_info: record<blogId: string, hasAdminAccess: bool, kind: string, photosAlbumKey: string, role: string, userId: string>, kind: string>
# operationId: blogger.blogUserInfos.get
export def "blogger-blog-user-infos-get" [
  user_id: string
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-posts: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{userId}/blogs/{blogId}"
    path_params: [{name: userId, var: user_id}, {name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxPosts, var: max_posts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_posts: $max_posts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists post and user info pairs.
#
# GET /v3/users/{userId}/blogs/{blogId}/posts
# Returns: record<items: table<kind: string, post: record, post_user_info: record>, kind: string, nextPageToken: string>
# operationId: blogger.postUserInfos.list
export def "blogger-post-user-infos-list" [
  user_id: string
  blog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --end-date: string
  --fetch-bodies: oneof<nothing, bool>
  --labels: string
  --max-results: int
  --order-by: string@order-by-completer
  --page-token: string
  --start-date: string
  --status: list<string>
  --view: string@view-completer
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{userId}/blogs/{blogId}/posts"
    path_params: [{name: userId, var: user_id}, {name: blogId, var: blog_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: endDate, var: end_date}, {name: fetchBodies, var: fetch_bodies}, {name: labels, var: labels}, {name: maxResults, var: max_results}, {name: orderBy, var: order_by}, {name: pageToken, var: page_token}, {name: startDate, var: start_date}, {name: status, var: status, style: multi}, {name: view, var: view}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, blog_id: $blog_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, end_date: $end_date, fetch_bodies: $fetch_bodies, labels: $labels, max_results: $max_results, order_by: $order_by, page_token: $page_token, start_date: $start_date, status: $status, view: $view
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets one post and user info pair, by post_id and user_id.
#
# GET /v3/users/{userId}/blogs/{blogId}/posts/{postId}
# Returns: record<kind: string, post: record<author: record<displayName: string, id: string, image: record, url: string>, blog: record<id: string>, content: string, customMetaData: string, etag: string, id: string, images: list<record>, kind: string, labels: list<string>, location: record<lat: float, lng: float, name: string, span: string>, published: string, readerComments: string, replies: record<items: list, selfLink: string, totalItems: string>, selfLink: string, status: string, title: string, titleLink: string, trashed: string, updated: string, url: string>, post_user_info: record<blogId: string, hasEditAccess: bool, kind: string, postId: string, userId: string>>
# operationId: blogger.postUserInfos.get
export def "blogger-post-user-infos-get" [
  user_id: string
  blog_id: string
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --max-comments: int
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{userId}/blogs/{blogId}/posts/{postId}"
    path_params: [{name: userId, var: user_id}, {name: blogId, var: blog_id}, {name: postId, var: post_id}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: maxComments, var: max_comments}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, blog_id: $blog_id, post_id: $post_id, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, max_comments: $max_comments
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
