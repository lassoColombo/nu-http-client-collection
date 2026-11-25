# Auto-generated client for Gitlab v3
# Source: https://api.apis.guru/v2/specs/gitlab.com/v3/swagger.json
# Auth: --token flag or $env.GITLAB_TOKEN

const CLIENT = {
  base_url: "https://gitlab.com/api"
  token_env_var: "GITLAB_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: private_header, in: header, header_name: PRIVATE_HEADER, prefix: ""}
    {name: query-private_token, in: query, header_name: private_token, prefix: ""}
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

def base-url-completer [] { ["https://gitlab.com/api"] }
def auth-scheme-completer [] { ["private_header" "query-private_token"] }

# Completers for enum parameters
def default-branch-protection-completer [] { ["0" "1" "2"] }
def default-project-visibility-completer [] { ["0" "10" "20"] }
def default-snippet-visibility-completer [] { ["0" "10" "20"] }
def default-group-visibility-completer [] { ["0" "10" "20"] }
def import-sources-completer [] { ["bitbucket" "fogbugz" "git" "github" "gitlab" "gitlab_project" "google_code"] }
def enabled-git-access-protocol-completer [] { ["http" "nil" "ssh"] }
def order-by-completer [] { ["name" "path"] }
def sort-completer [] { ["asc" "desc"] }
def state-completer [] { ["all" "closed" "opened"] }
def order-by-completer-1 [] { ["created_at" "updated_at"] }
def visibility-completer [] { ["internal" "private" "public"] }
def order-by-completer-2 [] { ["created_at" "id" "last_activity_at" "name" "path" "updated_at"] }
def visibility-level-completer [] { ["0" "10" "20"] }
def scope-completer [] { ["canceled" "failed" "pending" "running" "success"] }
def state-event-completer [] { ["close" "reopen"] }
def state-event-completer-1 [] { ["close" "merge" "reopen"] }
def state-completer-1 [] { ["all" "closed" "merged" "opened"] }
def state-completer-2 [] { ["active" "all" "closed"] }
def state-event-completer-2 [] { ["activate" "close"] }
def scope-completer-1 [] { ["branches" "running" "tags"] }
def line-type-completer [] { ["new" "old"] }
def encoding-completer [] { ["base64"] }
def scope-completer-2 [] { ["active" "online" "paused" "shared" "specific"] }
def service-slug-completer [] { ["asana" "assembla" "bamboo" "bugzilla" "buildkite" "builds-email" "campfire" "custom-issue-tracker" "drone-ci" "emails-on-push" "external-wiki" "flowdock" "gemnasium" "hipchat" "irker" "jira" "kubernetes" "mattermost" "mattermost-slash-commands" "pipelines-email" "pivotaltracker" "pushover" "redmine" "slack" "slack-slash-commands" "teamcity"] }
def group-access-completer [] { ["10" "20" "30" "40"] }
def state-completer-3 [] { ["canceled" "failed" "pending" "running" "success"] }
def scope-completer-3 [] { ["active" "online" "paused"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-v3-application-settings: "record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string>"
    put-v3-application-settings: "record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string>"
    get-v3-dockerfiles: "record<name: string>"
    get-v3-dockerfiles-name: "record<content: string, name: string>"
    get-v3-gitignores: "record<name: string>"
    get-v3-gitignores-name: "record<content: string, name: string>"
    get-v3-gitlab-ci-ymls: "record<name: string>"
    get-v3-gitlab-ci-ymls-name: "record<content: string, name: string>"
    get-v3-groups: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>"
    post-v3-groups: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>"
    get-v3-groups-owned: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>"
    get-v3-groups-id: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string>"
    put-v3-groups-id: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>"
    get-v3-groups-id-access-requests: "record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>"
    post-v3-groups-id-access-requests: "record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>"
    put-v3-groups-id-access-requests-user-id-approve: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-groups-id-issues: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-groups-id-members: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    post-v3-groups-id-members: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-groups-id-members-user-id: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    put-v3-groups-id-members-user-id: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-groups-id-notification-settings: "record<events: string, level: string>"
    put-v3-groups-id-notification-settings: "record<events: string, level: string>"
    get-v3-groups-id-projects: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    post-v3-groups-id-projects-project-id: "record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string>"
    get-v3-hooks: "record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>"
    post-v3-hooks: "record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>"
    delete-v3-hooks-id: "record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>"
    get-v3-hooks-id: "record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>"
    get-v3-issues: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-keys-id: "record<can_push: string, created_at: string, id: string, key: string, title: string, user: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>>"
    get-v3-licenses: "record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>"
    get-v3-licenses-name: "record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>"
    get-v3-namespaces: "record<id: string, kind: string, name: string, path: string>"
    get-v3-notification-settings: "record<events: string, level: string, notification_email: string>"
    put-v3-notification-settings: "record<events: string, level: string, notification_email: string>"
    get-v3-projects: "record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>"
    post-v3-projects: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-all: "record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>"
    post-v3-projects-fork-id: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-owned: "record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>"
    get-v3-projects-search-query: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-starred: "record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>"
    post-v3-projects-user-user-id: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-visible: "record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>"
    get-v3-projects-id: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, permissions: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    put-v3-projects-id: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    post-v3-projects-idref-reftrigger-builds: "record<id: string, variables: string>"
    get-v3-projects-id-access-requests: "record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>"
    post-v3-projects-id-access-requests: "record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>"
    put-v3-projects-id-access-requests-user-id-approve: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    post-v3-projects-id-archive: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-id-boards: "record<id: string, lists: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>>"
    get-v3-projects-id-boards-board-id-lists: "record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>"
    post-v3-projects-id-boards-board-id-lists: "record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>"
    delete-v3-projects-id-boards-board-id-lists-list-id: "record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>"
    get-v3-projects-id-boards-board-id-lists-list-id: "record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>"
    put-v3-projects-id-boards-board-id-lists-list-id: "record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>"
    get-v3-projects-id-builds: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    get-v3-projects-id-builds-build-id: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-builds-build-id-artifacts-keep: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-builds-build-id-cancel: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-builds-build-id-erase: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-builds-build-id-play: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-builds-build-id-retry: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    get-v3-projects-id-deploy-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-projects-id-deploy-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-projects-id-deploy-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    get-v3-projects-id-deploy-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-projects-id-deploy-keys-key-id-disable: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-projects-id-deploy-keys-key-id-enable: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    get-v3-projects-id-deployments: "record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-deployments-deployment-id: "record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-environments: "record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>"
    post-v3-projects-id-environments: "record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>"
    delete-v3-projects-id-environments-environment-id: "record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>"
    put-v3-projects-id-environments-environment-id: "record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>"
    get-v3-projects-id-events: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string>"
    get-v3-projects-id-hooks: "record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>"
    post-v3-projects-id-hooks: "record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>"
    delete-v3-projects-id-hooks-hook-id: "record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>"
    get-v3-projects-id-hooks-hook-id: "record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>"
    put-v3-projects-id-hooks-hook-id: "record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>"
    get-v3-projects-id-issues: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    post-v3-projects-id-issues: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-projects-id-issues-issue-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    put-v3-projects-id-issues-issue-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-projects-id-issues-issue-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-issues-issue-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-issues-issue-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-issues-issue-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-issues-issue-id-move: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-issues-issue-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-issues-issue-id-todo: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>"
    get-v3-projects-id-issues-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    post-v3-projects-id-issues-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    delete-v3-projects-id-issues-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    get-v3-projects-id-issues-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    put-v3-projects-id-issues-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    delete-v3-projects-id-issues-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    post-v3-projects-id-issues-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-projects-id-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-projects-id-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-projects-id-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    get-v3-projects-id-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-projects-id-keys-key-id-disable: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-projects-id-keys-key-id-enable: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-projects-id-labels: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    get-v3-projects-id-labels: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    post-v3-projects-id-labels: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    put-v3-projects-id-labels: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    delete-v3-projects-id-labels-subscribable-id-subscription: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    post-v3-projects-id-labels-subscribable-id-subscription: "record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>"
    get-v3-projects-id-members: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    post-v3-projects-id-members: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-projects-id-members-user-id: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    put-v3-projects-id-members-user-id: "record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-projects-id-merge-request-merge-request-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    put-v3-projects-id-merge-request-merge-request-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    post-v3-projects-id-merge-request-merge-request-id-cancel-merge-when-build-succeeds: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-request-merge-request-id-changes: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-request-merge-request-id-closes-issues: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    get-v3-projects-id-merge-request-merge-request-id-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    post-v3-projects-id-merge-request-merge-request-id-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    get-v3-projects-id-merge-request-merge-request-id-commits: "record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>"
    put-v3-projects-id-merge-request-merge-request-id-merge: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    delete-v3-projects-id-merge-request-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    post-v3-projects-id-merge-request-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    post-v3-projects-id-merge-requests: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests-merge-request-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    put-v3-projects-id-merge-requests-merge-request-id: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests-merge-request-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-merge-requests-merge-request-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-merge-requests-merge-request-id-cancel-merge-when-build-succeeds: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests-merge-request-id-changes: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests-merge-request-id-closes-issues: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    get-v3-projects-id-merge-requests-merge-request-id-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    post-v3-projects-id-merge-requests-merge-request-id-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>"
    get-v3-projects-id-merge-requests-merge-request-id-commits: "record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>"
    put-v3-projects-id-merge-requests-merge-request-id-merge: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-merge-requests-merge-request-id-todo: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>"
    get-v3-projects-id-merge-requests-merge-request-id-versions: "record<base_commit_sha: string, created_at: string, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string>"
    get-v3-projects-id-merge-requests-merge-request-id-versions-version-id: "record<base_commit_sha: string, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, created_at: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string>"
    get-v3-projects-id-merge-requests-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    post-v3-projects-id-merge-requests-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    delete-v3-projects-id-merge-requests-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    get-v3-projects-id-merge-requests-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    put-v3-projects-id-merge-requests-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    delete-v3-projects-id-merge-requests-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    post-v3-projects-id-merge-requests-subscribable-id-subscription: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>"
    get-v3-projects-id-milestones: "record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>"
    post-v3-projects-id-milestones: "record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>"
    get-v3-projects-id-milestones-milestone-id: "record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>"
    put-v3-projects-id-milestones-milestone-id: "record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>"
    get-v3-projects-id-milestones-milestone-id-issues: "record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>"
    get-v3-projects-id-notification-settings: "record<events: string, level: string>"
    put-v3-projects-id-notification-settings: "record<events: string, level: string>"
    post-v3-projects-id-pipeline: "record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>"
    get-v3-projects-id-pipelines: "record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>"
    get-v3-projects-id-pipelines-pipeline-id: "record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>"
    post-v3-projects-id-pipelines-pipeline-id-cancel: "record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>"
    post-v3-projects-id-pipelines-pipeline-id-retry: "record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>"
    get-v3-projects-id-repository-branches: "record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>"
    post-v3-projects-id-repository-branches: "record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>"
    get-v3-projects-id-repository-branches-branch: "record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>"
    put-v3-projects-id-repository-branches-branch-protect: "record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>"
    put-v3-projects-id-repository-branches-branch-unprotect: "record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>"
    get-v3-projects-id-repository-commits: "record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>"
    post-v3-projects-id-repository-commits: "record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string>"
    get-v3-projects-id-repository-commits-sha: "record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string>"
    get-v3-projects-id-repository-commits-sha-builds: "record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>"
    post-v3-projects-id-repository-commits-sha-cherry-pick: "record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>"
    get-v3-projects-id-repository-commits-sha-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string>"
    post-v3-projects-id-repository-commits-sha-comments: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string>"
    get-v3-projects-id-repository-commits-sha-statuses: "record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string>"
    get-v3-projects-id-repository-compare: "record<commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, compare_same_ref: string, compare_timeout: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>>"
    get-v3-projects-id-repository-contributors: "record<additions: string, commits: string, deletions: string, email: string, name: string>"
    get-v3-projects-id-repository-tags: "record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>"
    post-v3-projects-id-repository-tags: "record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>"
    get-v3-projects-id-repository-tags-tag-name: "record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>"
    post-v3-projects-id-repository-tags-tag-name-release: "record<description: string, tag_name: string>"
    put-v3-projects-id-repository-tags-tag-name-release: "record<description: string, tag_name: string>"
    get-v3-projects-id-repository-tree: "record<id: string, mode: string, name: string, path: string, type: string>"
    get-v3-projects-id-runners: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    post-v3-projects-id-runners: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    delete-v3-projects-id-runners-runner-id: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    get-v3-projects-id-services-service-slug: "record<active: string, build_events: string, created_at: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, properties: string, push_events: string, tag_push_events: string, title: string, updated_at: string>"
    post-v3-projects-id-share: "record<expires_at: string, group_access: string, group_id: string, id: string, project_id: string>"
    get-v3-projects-id-snippets: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>"
    post-v3-projects-id-snippets: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>"
    get-v3-projects-id-snippets-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    post-v3-projects-id-snippets-noteable-id-notes: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    delete-v3-projects-id-snippets-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    get-v3-projects-id-snippets-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    put-v3-projects-id-snippets-noteable-id-notes-note-id: "record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>"
    get-v3-projects-id-snippets-snippet-id: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>"
    put-v3-projects-id-snippets-snippet-id: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>"
    get-v3-projects-id-snippets-snippet-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-snippets-snippet-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-snippets-snippet-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-snippets-snippet-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    post-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id: "record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>"
    delete-v3-projects-id-star: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    post-v3-projects-id-star: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    post-v3-projects-id-statuses-sha: "record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string>"
    get-v3-projects-id-triggers: "record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>"
    post-v3-projects-id-triggers: "record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>"
    delete-v3-projects-id-triggers-token: "record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>"
    get-v3-projects-id-triggers-token: "record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>"
    post-v3-projects-id-unarchive: "record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>"
    get-v3-projects-id-users: "record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>"
    get-v3-projects-id-variables: "record<key: string, value: string>"
    post-v3-projects-id-variables: "record<key: string, value: string>"
    delete-v3-projects-id-variables-key: "record<key: string, value: string>"
    get-v3-projects-id-variables-key: "record<key: string, value: string>"
    put-v3-projects-id-variables-key: "record<key: string, value: string>"
    get-v3-runners: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    get-v3-runners-all: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    delete-v3-runners-id: "record<active: string, description: string, id: string, is_shared: string, name: string>"
    get-v3-runners-id: "record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string>"
    put-v3-runners-id: "record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string>"
    post-v3-session: "record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, private_token: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>"
    get-v3-snippets: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    post-v3-snippets: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    get-v3-snippets-public: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    delete-v3-snippets-id: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    get-v3-snippets-id: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    put-v3-snippets-id: "record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>"
    get-v3-templates-dockerfiles: "record<name: string>"
    get-v3-templates-dockerfiles-name: "record<content: string, name: string>"
    get-v3-templates-gitignores: "record<name: string>"
    get-v3-templates-gitignores-name: "record<content: string, name: string>"
    get-v3-templates-gitlab-ci-ymls: "record<name: string>"
    get-v3-templates-gitlab-ci-ymls-name: "record<content: string, name: string>"
    get-v3-templates-licenses: "record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>"
    get-v3-templates-licenses-name: "record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>"
    get-v3-todos: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>"
    delete-v3-todos-id: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>"
    get-v3-user: "record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>"
    get-v3-user-emails: "record<email: string, id: string>"
    post-v3-user-emails: "record<email: string, id: string>"
    get-v3-user-emails-email-id: "record<email: string, id: string>"
    get-v3-user-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-user-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-user-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    get-v3-user-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    get-v3-users: "record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>"
    post-v3-users: "record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>"
    delete-v3-users-id: "record<email: string, id: string>"
    get-v3-users-id: "record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>"
    put-v3-users-id: "record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>"
    get-v3-users-id-emails: "record<email: string, id: string>"
    post-v3-users-id-emails: "record<email: string, id: string>"
    delete-v3-users-id-emails-email-id: "record<email: string, id: string>"
    get-v3-users-id-events: "record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, \"downvote?\": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, \"upvote?\": string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string>"
    get-v3-users-id-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    post-v3-users-id-keys: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
    delete-v3-users-id-keys-key-id: "record<can_push: string, created_at: string, id: string, key: string, title: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v3-application-settings" "put-v3-application-settings" "post-v3-ci-lint" "get-v3-deploy-keys" "get-v3-dockerfiles" "get-v3-dockerfiles-name" "get-v3-gitignores" "get-v3-gitignores-name" "get-v3-gitlab-ci-ymls" "get-v3-gitlab-ci-ymls-name" "get-v3-groups" "post-v3-groups" "get-v3-groups-owned" "delete-v3-groups-id" "get-v3-groups-id" "put-v3-groups-id" "get-v3-groups-id-access-requests" "post-v3-groups-id-access-requests" "delete-v3-groups-id-access-requests-user-id" "put-v3-groups-id-access-requests-user-id-approve" "get-v3-groups-id-issues" "get-v3-groups-id-members" "post-v3-groups-id-members" "delete-v3-groups-id-members-user-id" "get-v3-groups-id-members-user-id" "put-v3-groups-id-members-user-id" "get-v3-groups-id-notification-settings" "put-v3-groups-id-notification-settings" "get-v3-groups-id-projects" "post-v3-groups-id-projects-project-id" "get-v3-hooks" "post-v3-hooks" "delete-v3-hooks-id" "get-v3-hooks-id" "post-v3-internal-allowed" "get-v3-internal-broadcast-message" "get-v3-internal-check" "get-v3-internal-discover" "post-v3-internal-lfs-authenticate" "get-v3-internal-merge-request-urls" "post-v3-internal-two-factor-recovery-codes" "get-v3-issues" "get-v3-keys-id" "get-v3-licenses" "get-v3-licenses-name" "get-v3-namespaces" "get-v3-notification-settings" "put-v3-notification-settings" "get-v3-projects" "post-v3-projects" "get-v3-projects-all" "post-v3-projects-fork-id" "get-v3-projects-owned" "get-v3-projects-search-query" "get-v3-projects-starred" "post-v3-projects-user-user-id" "get-v3-projects-visible" "delete-v3-projects-id" "get-v3-projects-id" "put-v3-projects-id" "post-v3-projects-idref-reftrigger-builds" "get-v3-projects-id-access-requests" "post-v3-projects-id-access-requests" "delete-v3-projects-id-access-requests-user-id" "put-v3-projects-id-access-requests-user-id-approve" "post-v3-projects-id-archive" "get-v3-projects-id-boards" "get-v3-projects-id-boards-board-id-lists" "post-v3-projects-id-boards-board-id-lists" "delete-v3-projects-id-boards-board-id-lists-list-id" "get-v3-projects-id-boards-board-id-lists-list-id" "put-v3-projects-id-boards-board-id-lists-list-id" "get-v3-projects-id-builds" "get-v3-projects-id-builds-artifacts-ref-name-download" "get-v3-projects-id-builds-build-id" "get-v3-projects-id-builds-build-id-artifacts" "post-v3-projects-id-builds-build-id-artifacts-keep" "post-v3-projects-id-builds-build-id-cancel" "post-v3-projects-id-builds-build-id-erase" "post-v3-projects-id-builds-build-id-play" "post-v3-projects-id-builds-build-id-retry" "get-v3-projects-id-builds-build-id-trace" "get-v3-projects-id-deploy-keys" "post-v3-projects-id-deploy-keys" "delete-v3-projects-id-deploy-keys-key-id" "get-v3-projects-id-deploy-keys-key-id" "delete-v3-projects-id-deploy-keys-key-id-disable" "post-v3-projects-id-deploy-keys-key-id-enable" "get-v3-projects-id-deployments" "get-v3-projects-id-deployments-deployment-id" "get-v3-projects-id-environments" "post-v3-projects-id-environments" "delete-v3-projects-id-environments-environment-id" "put-v3-projects-id-environments-environment-id" "get-v3-projects-id-events" "delete-v3-projects-id-fork" "post-v3-projects-id-fork-forked-from-id" "get-v3-projects-id-hooks" "post-v3-projects-id-hooks" "delete-v3-projects-id-hooks-hook-id" "get-v3-projects-id-hooks-hook-id" "put-v3-projects-id-hooks-hook-id" "get-v3-projects-id-issues" "post-v3-projects-id-issues" "delete-v3-projects-id-issues-issue-id" "get-v3-projects-id-issues-issue-id" "put-v3-projects-id-issues-issue-id" "post-v3-projects-id-issues-issue-id-add-spent-time" "get-v3-projects-id-issues-issue-id-award-emoji" "post-v3-projects-id-issues-issue-id-award-emoji" "delete-v3-projects-id-issues-issue-id-award-emoji-award-id" "get-v3-projects-id-issues-issue-id-award-emoji-award-id" "post-v3-projects-id-issues-issue-id-move" "get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji" "post-v3-projects-id-issues-issue-id-notes-note-id-award-emoji" "delete-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id" "get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id" "post-v3-projects-id-issues-issue-id-reset-spent-time" "post-v3-projects-id-issues-issue-id-reset-time-estimate" "post-v3-projects-id-issues-issue-id-time-estimate" "get-v3-projects-id-issues-issue-id-time-stats" "post-v3-projects-id-issues-issue-id-todo" "get-v3-projects-id-issues-noteable-id-notes" "post-v3-projects-id-issues-noteable-id-notes" "delete-v3-projects-id-issues-noteable-id-notes-note-id" "get-v3-projects-id-issues-noteable-id-notes-note-id" "put-v3-projects-id-issues-noteable-id-notes-note-id" "delete-v3-projects-id-issues-subscribable-id-subscription" "post-v3-projects-id-issues-subscribable-id-subscription" "get-v3-projects-id-keys" "post-v3-projects-id-keys" "delete-v3-projects-id-keys-key-id" "get-v3-projects-id-keys-key-id" "delete-v3-projects-id-keys-key-id-disable" "post-v3-projects-id-keys-key-id-enable" "delete-v3-projects-id-labels" "get-v3-projects-id-labels" "post-v3-projects-id-labels" "put-v3-projects-id-labels" "delete-v3-projects-id-labels-subscribable-id-subscription" "post-v3-projects-id-labels-subscribable-id-subscription" "get-v3-projects-id-members" "post-v3-projects-id-members" "delete-v3-projects-id-members-user-id" "get-v3-projects-id-members-user-id" "put-v3-projects-id-members-user-id" "get-v3-projects-id-merge-request-merge-request-id" "put-v3-projects-id-merge-request-merge-request-id" "post-v3-projects-id-merge-request-merge-request-id-cancel-merge-when-build-succeeds" "get-v3-projects-id-merge-request-merge-request-id-changes" "get-v3-projects-id-merge-request-merge-request-id-closes-issues" "get-v3-projects-id-merge-request-merge-request-id-comments" "post-v3-projects-id-merge-request-merge-request-id-comments" "get-v3-projects-id-merge-request-merge-request-id-commits" "put-v3-projects-id-merge-request-merge-request-id-merge" "delete-v3-projects-id-merge-request-subscribable-id-subscription" "post-v3-projects-id-merge-request-subscribable-id-subscription" "get-v3-projects-id-merge-requests" "post-v3-projects-id-merge-requests" "delete-v3-projects-id-merge-requests-merge-request-id" "get-v3-projects-id-merge-requests-merge-request-id" "put-v3-projects-id-merge-requests-merge-request-id" "post-v3-projects-id-merge-requests-merge-request-id-add-spent-time" "get-v3-projects-id-merge-requests-merge-request-id-award-emoji" "post-v3-projects-id-merge-requests-merge-request-id-award-emoji" "delete-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id" "get-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id" "post-v3-projects-id-merge-requests-merge-request-id-cancel-merge-when-build-succeeds" "get-v3-projects-id-merge-requests-merge-request-id-changes" "get-v3-projects-id-merge-requests-merge-request-id-closes-issues" "get-v3-projects-id-merge-requests-merge-request-id-comments" "post-v3-projects-id-merge-requests-merge-request-id-comments" "get-v3-projects-id-merge-requests-merge-request-id-commits" "put-v3-projects-id-merge-requests-merge-request-id-merge" "get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji" "post-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji" "delete-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id" "get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id" "post-v3-projects-id-merge-requests-merge-request-id-reset-spent-time" "post-v3-projects-id-merge-requests-merge-request-id-reset-time-estimate" "post-v3-projects-id-merge-requests-merge-request-id-time-estimate" "get-v3-projects-id-merge-requests-merge-request-id-time-stats" "post-v3-projects-id-merge-requests-merge-request-id-todo" "get-v3-projects-id-merge-requests-merge-request-id-versions" "get-v3-projects-id-merge-requests-merge-request-id-versions-version-id" "get-v3-projects-id-merge-requests-noteable-id-notes" "post-v3-projects-id-merge-requests-noteable-id-notes" "delete-v3-projects-id-merge-requests-noteable-id-notes-note-id" "get-v3-projects-id-merge-requests-noteable-id-notes-note-id" "put-v3-projects-id-merge-requests-noteable-id-notes-note-id" "delete-v3-projects-id-merge-requests-subscribable-id-subscription" "post-v3-projects-id-merge-requests-subscribable-id-subscription" "get-v3-projects-id-milestones" "post-v3-projects-id-milestones" "get-v3-projects-id-milestones-milestone-id" "put-v3-projects-id-milestones-milestone-id" "get-v3-projects-id-milestones-milestone-id-issues" "get-v3-projects-id-notification-settings" "put-v3-projects-id-notification-settings" "post-v3-projects-id-pipeline" "get-v3-projects-id-pipelines" "get-v3-projects-id-pipelines-pipeline-id" "post-v3-projects-id-pipelines-pipeline-id-cancel" "post-v3-projects-id-pipelines-pipeline-id-retry" "get-v3-projects-id-repository-archive" "get-v3-projects-id-repository-blobs-sha" "get-v3-projects-id-repository-branches" "post-v3-projects-id-repository-branches" "delete-v3-projects-id-repository-branches-branch" "get-v3-projects-id-repository-branches-branch" "put-v3-projects-id-repository-branches-branch-protect" "put-v3-projects-id-repository-branches-branch-unprotect" "get-v3-projects-id-repository-commits" "post-v3-projects-id-repository-commits" "get-v3-projects-id-repository-commits-sha" "get-v3-projects-id-repository-commits-sha-blob" "get-v3-projects-id-repository-commits-sha-builds" "post-v3-projects-id-repository-commits-sha-cherry-pick" "get-v3-projects-id-repository-commits-sha-comments" "post-v3-projects-id-repository-commits-sha-comments" "get-v3-projects-id-repository-commits-sha-diff" "get-v3-projects-id-repository-commits-sha-statuses" "get-v3-projects-id-repository-compare" "get-v3-projects-id-repository-contributors" "delete-v3-projects-id-repository-files" "get-v3-projects-id-repository-files" "post-v3-projects-id-repository-files" "put-v3-projects-id-repository-files" "delete-v3-projects-id-repository-merged-branches" "get-v3-projects-id-repository-raw-blobs-sha" "get-v3-projects-id-repository-tags" "post-v3-projects-id-repository-tags" "delete-v3-projects-id-repository-tags-tag-name" "get-v3-projects-id-repository-tags-tag-name" "post-v3-projects-id-repository-tags-tag-name-release" "put-v3-projects-id-repository-tags-tag-name-release" "get-v3-projects-id-repository-tree" "get-v3-projects-id-runners" "post-v3-projects-id-runners" "delete-v3-projects-id-runners-runner-id" "put-v3-projects-id-services-asana" "put-v3-projects-id-services-assembla" "put-v3-projects-id-services-bamboo" "put-v3-projects-id-services-bugzilla" "put-v3-projects-id-services-buildkite" "put-v3-projects-id-services-builds-email" "put-v3-projects-id-services-campfire" "put-v3-projects-id-services-custom-issue-tracker" "put-v3-projects-id-services-drone-ci" "put-v3-projects-id-services-emails-on-push" "put-v3-projects-id-services-external-wiki" "put-v3-projects-id-services-flowdock" "put-v3-projects-id-services-gemnasium" "put-v3-projects-id-services-hipchat" "put-v3-projects-id-services-irker" "put-v3-projects-id-services-jira" "put-v3-projects-id-services-kubernetes" "put-v3-projects-id-services-mattermost" "put-v3-projects-id-services-mattermost-slash-commands" "post-v3-projects-id-services-mattermost-slash-commands-trigger" "put-v3-projects-id-services-pipelines-email" "put-v3-projects-id-services-pivotaltracker" "put-v3-projects-id-services-pushover" "put-v3-projects-id-services-redmine" "put-v3-projects-id-services-slack" "put-v3-projects-id-services-slack-slash-commands" "post-v3-projects-id-services-slack-slash-commands-trigger" "put-v3-projects-id-services-teamcity" "delete-v3-projects-id-services-service-slug" "get-v3-projects-id-services-service-slug" "post-v3-projects-id-share" "delete-v3-projects-id-share-group-id" "get-v3-projects-id-snippets" "post-v3-projects-id-snippets" "get-v3-projects-id-snippets-noteable-id-notes" "post-v3-projects-id-snippets-noteable-id-notes" "delete-v3-projects-id-snippets-noteable-id-notes-note-id" "get-v3-projects-id-snippets-noteable-id-notes-note-id" "put-v3-projects-id-snippets-noteable-id-notes-note-id" "delete-v3-projects-id-snippets-snippet-id" "get-v3-projects-id-snippets-snippet-id" "put-v3-projects-id-snippets-snippet-id" "get-v3-projects-id-snippets-snippet-id-award-emoji" "post-v3-projects-id-snippets-snippet-id-award-emoji" "delete-v3-projects-id-snippets-snippet-id-award-emoji-award-id" "get-v3-projects-id-snippets-snippet-id-award-emoji-award-id" "get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji" "post-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji" "delete-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id" "get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id" "get-v3-projects-id-snippets-snippet-id-raw" "delete-v3-projects-id-star" "post-v3-projects-id-star" "post-v3-projects-id-statuses-sha" "get-v3-projects-id-triggers" "post-v3-projects-id-triggers" "delete-v3-projects-id-triggers-token" "get-v3-projects-id-triggers-token" "post-v3-projects-id-unarchive" "post-v3-projects-id-uploads" "get-v3-projects-id-users" "get-v3-projects-id-variables" "post-v3-projects-id-variables" "delete-v3-projects-id-variables-key" "get-v3-projects-id-variables-key" "put-v3-projects-id-variables-key" "get-v3-runners" "get-v3-runners-all" "delete-v3-runners-id" "get-v3-runners-id" "put-v3-runners-id" "post-v3-session" "get-v3-sidekiq-compound-metrics" "get-v3-sidekiq-job-stats" "get-v3-sidekiq-process-metrics" "get-v3-sidekiq-queue-metrics" "get-v3-snippets" "post-v3-snippets" "get-v3-snippets-public" "delete-v3-snippets-id" "get-v3-snippets-id" "put-v3-snippets-id" "get-v3-snippets-id-raw" "get-v3-templates-dockerfiles" "get-v3-templates-dockerfiles-name" "get-v3-templates-gitignores" "get-v3-templates-gitignores-name" "get-v3-templates-gitlab-ci-ymls" "get-v3-templates-gitlab-ci-ymls-name" "get-v3-templates-licenses" "get-v3-templates-licenses-name" "delete-v3-todos" "get-v3-todos" "delete-v3-todos-id" "get-v3-user" "get-v3-user-emails" "post-v3-user-emails" "delete-v3-user-emails-email-id" "get-v3-user-emails-email-id" "get-v3-user-keys" "post-v3-user-keys" "delete-v3-user-keys-key-id" "get-v3-user-keys-key-id" "get-v3-users" "post-v3-users" "delete-v3-users-id" "get-v3-users-id" "put-v3-users-id" "put-v3-users-id-block" "get-v3-users-id-emails" "post-v3-users-id-emails" "delete-v3-users-id-emails-email-id" "get-v3-users-id-events" "get-v3-users-id-keys" "post-v3-users-id-keys" "delete-v3-users-id-keys-key-id" "put-v3-users-id-unblock" "get-v3-version" "commands"] | sort) } | get name | first)
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

# Get the current application settings
#
# GET /v3/application/settings
# Returns: record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string>
# operationId: getV3ApplicationSettings
export def "get-v3-application-settings" [
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
    path: "/v3/application/settings"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify application settings
#
# PUT /v3/application/settings
# Returns: record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string>
# operationId: putV3ApplicationSettings
export def "put-v3-application-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-branch-protection: int@default-branch-protection-completer # Determine if developers can push to master
  --default-project-visibility: int@default-project-visibility-completer # The default project visibility
  --default-snippet-visibility: int@default-snippet-visibility-completer # The default snippet visibility
  --default-group-visibility: int@default-group-visibility-completer # The default group visibility
  --restricted-visibility-levels: list<string> # Selected levels cannot be used by non-admin users for projects or snippets. If the public level is restricted, user profiles are only visible to logged in users.
  --import-sources: list<string>@import-sources-completer # Enabled sources for code import during project creation. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com
  --disabled-oauth-sign-in-sources: list<string> # Disable certain OAuth sign-in sources
  --enabled-git-access-protocol: string@enabled-git-access-protocol-completer # Allow only the selected protocols to be used for Git access.
  --gravatar-enabled: oneof<nothing, bool> # Flag indicating if the Gravatar service is enabled
  --default-projects-limit: int # The maximum number of personal projects
  --max-attachment-size: int # Maximum attachment size in MB
  --session-expire-delay: int # Session duration in minutes. GitLab restart is required to apply changes.
  --user-oauth-applications: oneof<nothing, bool> # Allow users to register any application to use GitLab as an OAuth provider
  --user-default-external: oneof<nothing, bool> # Newly registered users will by default be external
  --signup-enabled: oneof<nothing, bool> # Flag indicating if sign up is enabled
  --send-user-confirmation-email: oneof<nothing, bool> # Send confirmation email on sign-up
  --domain-whitelist: string # ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com
  --domain-blacklist-enabled: oneof<nothing, bool> # Enable domain blacklist for sign ups
  domain_blacklist: string # Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com
  --after-sign-up-text: string # Text shown after sign up
  --signin-enabled: oneof<nothing, bool> # Flag indicating if sign in is enabled
  --require-two-factor-authentication: oneof<nothing, bool> # Require all users to setup Two-factor authentication
  two_factor_grace_period: int # Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication
  --home-page-url: string # We will redirect non-logged in users to this page
  --after-sign-out-path: string # We will redirect users to this page after they sign out
  --sign-in-text: string # The sign in text of the GitLab application
  --help-page-text: string # Custom text displayed on the help page
  --shared-runners-enabled: oneof<nothing, bool> # Enable shared runners for new projects
  shared_runners_text: string # Shared runners text
  --max-artifacts-size: int # Set the maximum file size each build's artifacts can have
  --container-registry-token-expire-delay: int # Authorization token duration (minutes)
  --metrics-enabled: oneof<nothing, bool> # Enable the InfluxDB metrics
  metrics_host: string # The InfluxDB host
  metrics_port: int # The UDP port to use for connecting to InfluxDB
  metrics_pool_size: int # The amount of InfluxDB connections to open
  metrics_timeout: int # The amount of seconds after which an InfluxDB connection will time out
  metrics_method_call_threshold: int # A method call is only tracked when it takes longer to complete than the given amount of milliseconds.
  metrics_sample_interval: int # The sampling interval in seconds
  metrics_packet_size: int # The amount of points to store in a single UDP packet
  --sidekiq-throttling-enabled: oneof<nothing, bool> # Enable Sidekiq Job Throttling
  sidekiq_throttling_queus: list<string> # Choose which queues you wish to throttle
  sidekiq_throttling_factor: float # The factor by which the queues should be throttled. A value between 0.0 and 1.0, exclusive.
  --recaptcha-enabled: oneof<nothing, bool> # Helps prevent bots from creating accounts
  recaptcha_site_key: string # Generate site key at http://www.google.com/recaptcha
  recaptcha_private_key: string # Generate private key at http://www.google.com/recaptcha
  --akismet-enabled: oneof<nothing, bool> # Helps prevent bots from creating issues
  akismet_api_key: string # Generate API key at http://www.akismet.com
  --admin-notification-email: string # Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.
  --sentry-enabled: oneof<nothing, bool> # Sentry is an error reporting and logging tool which is currently not shipped with GitLab, get it here: https://getsentry.com
  sentry_dsn: string # Sentry Data Source Name
  --repository-storage: string # Storage paths for new projects
  --repository-checks-enabled: oneof<nothing, bool> # GitLab will periodically run 'git fsck' in all project and wiki repositories to look for silent disk corruption issues.
  --koding-enabled: oneof<nothing, bool> # Enable Koding
  koding_url: string # The Koding team URL
  --plantuml-enabled: oneof<nothing, bool> # Enable PlantUML
  plantuml_url: string # The PlantUML server URL
  --version-check-enabled: oneof<nothing, bool> # Let GitLab inform you when an update is available.
  --email-author-in-body: oneof<nothing, bool> # Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead.
  --html-emails-enabled: oneof<nothing, bool> # By default GitLab sends emails in HTML and plain text formats so mail clients can choose what format to use. Disable this option if you only want to send emails in plain text format.
  --housekeeping-enabled: oneof<nothing, bool> # Enable automatic repository housekeeping (git repack, git gc)
  --housekeeping-bitmaps-enabled: oneof<nothing, bool> # Creating pack file bitmaps makes housekeeping take a little longer but bitmaps should accelerate 'git clone' performance.
  housekeeping_incremental_repack_period: int # Number of Git pushes after which an incremental 'git repack' is run.
  housekeeping_full_repack_period: int # Number of Git pushes after which a full 'git repack' is run.
  housekeeping_gc_period: int # Number of Git pushes after which 'git gc' is run.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/application/settings"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: default_branch_protection, var: default_branch_protection}, {name: default_project_visibility, var: default_project_visibility}, {name: default_snippet_visibility, var: default_snippet_visibility}, {name: default_group_visibility, var: default_group_visibility}, {name: restricted_visibility_levels, var: restricted_visibility_levels, join: ","}, {name: import_sources, var: import_sources, join: ","}, {name: disabled_oauth_sign_in_sources, var: disabled_oauth_sign_in_sources, join: ","}, {name: enabled_git_access_protocol, var: enabled_git_access_protocol}, {name: gravatar_enabled, var: gravatar_enabled}, {name: default_projects_limit, var: default_projects_limit}, {name: max_attachment_size, var: max_attachment_size}, {name: session_expire_delay, var: session_expire_delay}, {name: user_oauth_applications, var: user_oauth_applications}, {name: user_default_external, var: user_default_external}, {name: signup_enabled, var: signup_enabled}, {name: send_user_confirmation_email, var: send_user_confirmation_email}, {name: domain_whitelist, var: domain_whitelist}, {name: domain_blacklist_enabled, var: domain_blacklist_enabled}, {name: domain_blacklist, var: domain_blacklist}, {name: after_sign_up_text, var: after_sign_up_text}, {name: signin_enabled, var: signin_enabled}, {name: require_two_factor_authentication, var: require_two_factor_authentication}, {name: two_factor_grace_period, var: two_factor_grace_period}, {name: home_page_url, var: home_page_url}, {name: after_sign_out_path, var: after_sign_out_path}, {name: sign_in_text, var: sign_in_text}, {name: help_page_text, var: help_page_text}, {name: shared_runners_enabled, var: shared_runners_enabled}, {name: shared_runners_text, var: shared_runners_text}, {name: max_artifacts_size, var: max_artifacts_size}, {name: container_registry_token_expire_delay, var: container_registry_token_expire_delay}, {name: metrics_enabled, var: metrics_enabled}, {name: metrics_host, var: metrics_host}, {name: metrics_port, var: metrics_port}, {name: metrics_pool_size, var: metrics_pool_size}, {name: metrics_timeout, var: metrics_timeout}, {name: metrics_method_call_threshold, var: metrics_method_call_threshold}, {name: metrics_sample_interval, var: metrics_sample_interval}, {name: metrics_packet_size, var: metrics_packet_size}, {name: sidekiq_throttling_enabled, var: sidekiq_throttling_enabled}, {name: sidekiq_throttling_queus, var: sidekiq_throttling_queus, join: ","}, {name: sidekiq_throttling_factor, var: sidekiq_throttling_factor}, {name: recaptcha_enabled, var: recaptcha_enabled}, {name: recaptcha_site_key, var: recaptcha_site_key}, {name: recaptcha_private_key, var: recaptcha_private_key}, {name: akismet_enabled, var: akismet_enabled}, {name: akismet_api_key, var: akismet_api_key}, {name: admin_notification_email, var: admin_notification_email}, {name: sentry_enabled, var: sentry_enabled}, {name: sentry_dsn, var: sentry_dsn}, {name: repository_storage, var: repository_storage}, {name: repository_checks_enabled, var: repository_checks_enabled}, {name: koding_enabled, var: koding_enabled}, {name: koding_url, var: koding_url}, {name: plantuml_enabled, var: plantuml_enabled}, {name: plantuml_url, var: plantuml_url}, {name: version_check_enabled, var: version_check_enabled}, {name: email_author_in_body, var: email_author_in_body}, {name: html_emails_enabled, var: html_emails_enabled}, {name: housekeeping_enabled, var: housekeeping_enabled}, {name: housekeeping_bitmaps_enabled, var: housekeeping_bitmaps_enabled, required: true}, {name: housekeeping_incremental_repack_period, var: housekeeping_incremental_repack_period}, {name: housekeeping_full_repack_period, var: housekeeping_full_repack_period}, {name: housekeeping_gc_period, var: housekeeping_gc_period}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    default_branch_protection: $default_branch_protection, default_project_visibility: $default_project_visibility, default_snippet_visibility: $default_snippet_visibility, default_group_visibility: $default_group_visibility, restricted_visibility_levels: $restricted_visibility_levels, import_sources: $import_sources, disabled_oauth_sign_in_sources: $disabled_oauth_sign_in_sources, enabled_git_access_protocol: $enabled_git_access_protocol, gravatar_enabled: $gravatar_enabled, default_projects_limit: $default_projects_limit, max_attachment_size: $max_attachment_size, session_expire_delay: $session_expire_delay, user_oauth_applications: $user_oauth_applications, user_default_external: $user_default_external, signup_enabled: $signup_enabled, send_user_confirmation_email: $send_user_confirmation_email, domain_whitelist: $domain_whitelist, domain_blacklist_enabled: $domain_blacklist_enabled, domain_blacklist: $domain_blacklist, after_sign_up_text: $after_sign_up_text, signin_enabled: $signin_enabled, require_two_factor_authentication: $require_two_factor_authentication, two_factor_grace_period: $two_factor_grace_period, home_page_url: $home_page_url, after_sign_out_path: $after_sign_out_path, sign_in_text: $sign_in_text, help_page_text: $help_page_text, shared_runners_enabled: $shared_runners_enabled, shared_runners_text: $shared_runners_text, max_artifacts_size: $max_artifacts_size, container_registry_token_expire_delay: $container_registry_token_expire_delay, metrics_enabled: $metrics_enabled, metrics_host: $metrics_host, metrics_port: $metrics_port, metrics_pool_size: $metrics_pool_size, metrics_timeout: $metrics_timeout, metrics_method_call_threshold: $metrics_method_call_threshold, metrics_sample_interval: $metrics_sample_interval, metrics_packet_size: $metrics_packet_size, sidekiq_throttling_enabled: $sidekiq_throttling_enabled, sidekiq_throttling_queus: $sidekiq_throttling_queus, sidekiq_throttling_factor: $sidekiq_throttling_factor, recaptcha_enabled: $recaptcha_enabled, recaptcha_site_key: $recaptcha_site_key, recaptcha_private_key: $recaptcha_private_key, akismet_enabled: $akismet_enabled, akismet_api_key: $akismet_api_key, admin_notification_email: $admin_notification_email, sentry_enabled: $sentry_enabled, sentry_dsn: $sentry_dsn, repository_storage: $repository_storage, repository_checks_enabled: $repository_checks_enabled, koding_enabled: $koding_enabled, koding_url: $koding_url, plantuml_enabled: $plantuml_enabled, plantuml_url: $plantuml_url, version_check_enabled: $version_check_enabled, email_author_in_body: $email_author_in_body, html_emails_enabled: $html_emails_enabled, housekeeping_enabled: $housekeeping_enabled, housekeeping_bitmaps_enabled: $housekeeping_bitmaps_enabled, housekeeping_incremental_repack_period: $housekeeping_incremental_repack_period, housekeeping_full_repack_period: $housekeeping_full_repack_period, housekeeping_gc_period: $housekeeping_gc_period
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Validation of .gitlab-ci.yml content
#
# POST /v3/ci/lint
# operationId: postV3CiLint
export def "post-v3-ci-lint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Content of .gitlab-ci.yml
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/ci/lint"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: content, var: content}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    content: $content
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/deploy_keys
#
# operationId: getV3DeployKeys
export def "get-v3-deploy-keys" [
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
    path: "/v3/deploy_keys"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/dockerfiles
# Returns: record<name: string>
# operationId: getV3Dockerfiles
export def "get-v3-dockerfiles" [
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
    path: "/v3/dockerfiles"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/dockerfiles/{name}
# Returns: record<content: string, name: string>
# operationId: getV3DockerfilesName
export def "get-v3-dockerfiles-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/dockerfiles/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/gitignores
# Returns: record<name: string>
# operationId: getV3Gitignores
export def "get-v3-gitignores" [
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
    path: "/v3/gitignores"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/gitignores/{name}
# Returns: record<content: string, name: string>
# operationId: getV3GitignoresName
export def "get-v3-gitignores-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/gitignores/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/gitlab_ci_ymls
# Returns: record<name: string>
# operationId: getV3GitlabCiYmls
export def "get-v3-gitlab-ci-ymls" [
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
    path: "/v3/gitlab_ci_ymls"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/gitlab_ci_ymls/{name}
# Returns: record<content: string, name: string>
# operationId: getV3GitlabCiYmlsName
export def "get-v3-gitlab-ci-ymls-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/gitlab_ci_ymls/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a groups list
#
# GET /v3/groups
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>
# operationId: getV3Groups
export def "get-v3-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistics: oneof<nothing, bool> # Include project statistics
  --all-available: oneof<nothing, bool> # Show all group that you have access to
  --search: string # Search for a specific group
  --order-by: string@order-by-completer # Order by name or path (default: name)
  --sort: string@sort-completer # Sort by asc (ascending) or desc (descending) (default: asc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups"
    query: [{name: statistics, var: statistics}, {name: all_available, var: all_available}, {name: search, var: search}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    statistics: $statistics, all_available: $all_available, search: $search, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group. Available only for users who can create groups.
#
# POST /v3/groups
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>
# operationId: postV3Groups
export def "post-v3-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the group
  path: string # The path of the group
  --description: string # The description of the group
  --visibility-level: int # The visibility level of the group
  --lfs-enabled: oneof<nothing, bool> # Enable/disable LFS for the projects in this group
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/groups"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: path, var: path}, {name: description, var: description}, {name: visibility_level, var: visibility_level}, {name: lfs_enabled, var: lfs_enabled}, {name: request_access_enabled, var: request_access_enabled}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    name: $name, path: $path, description: $description, visibility_level: $visibility_level, lfs_enabled: $lfs_enabled, request_access_enabled: $request_access_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get list of owned groups for authenticated user
#
# GET /v3/groups/owned
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>
# operationId: getV3GroupsOwned
export def "get-v3-groups-owned" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/owned"
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: statistics, var: statistics}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    page: $page, per_page: $per_page, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a group.
#
# DELETE /v3/groups/{id}
# operationId: deleteV3GroupsId
export def "delete-v3-groups-id" [
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
    path: "/v3/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single group, with containing projects.
#
# GET /v3/groups/{id}
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string>
# operationId: getV3GroupsId
export def "get-v3-groups-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a group. Available only for users who can administrate groups.
#
# PUT /v3/groups/{id}
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string>
# operationId: putV3GroupsId
export def "put-v3-groups-id" [
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
  --name: string # The name of the group
  --path: string # The path of the group
  --description: string # The description of the group
  --visibility-level: int # The visibility level of the group
  --lfs-enabled: oneof<nothing, bool> # Enable/disable LFS for the projects in this group
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/groups/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: path, var: path}, {name: description, var: description}, {name: visibility_level, var: visibility_level}, {name: lfs_enabled, var: lfs_enabled}, {name: request_access_enabled, var: request_access_enabled}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, name: $name, path: $path, description: $description, visibility_level: $visibility_level, lfs_enabled: $lfs_enabled, request_access_enabled: $request_access_enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of access requests for a group.
#
# GET /v3/groups/{id}/access_requests
# Returns: record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>
# operationId: getV3GroupsIdAccessRequests
export def "get-v3-groups-id-access-requests" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}/access_requests"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests access for the authenticated user to a group.
#
# POST /v3/groups/{id}/access_requests
# Returns: record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>
# operationId: postV3GroupsIdAccessRequests
export def "post-v3-groups-id-access-requests" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/groups/{id}/access_requests"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Denies an access request for the given user.
#
# DELETE /v3/groups/{id}/access_requests/{user_id}
# operationId: deleteV3GroupsIdAccessRequestsUserId
export def "delete-v3-groups-id-access-requests-user-id" [
  id: string
  user_id: int
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
    path: "/v3/groups/{id}/access_requests/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approves an access request for the given user.
#
# PUT /v3/groups/{id}/access_requests/{user_id}/approve
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: putV3GroupsIdAccessRequestsUserIdApprove
export def "put-v3-groups-id-access-requests-user-id-approve" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-level: int # A valid access level (defaults: `30`, developer access level)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/groups/{id}/access_requests/{user_id}/approve"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: access_level, var: access_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of group issues
#
# GET /v3/groups/{id}/issues
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: getV3GroupsIdIssues
export def "get-v3-groups-id-issues" [
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
  --state: string@state-completer # Return opened, closed, or all issues (default: opened)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}/issues"
    path_params: [{name: id, var: id}]
    query: [{name: state, var: state}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, state: $state, labels: $labels, milestone: $milestone, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of group or project members viewable by the authenticated user.
#
# GET /v3/groups/{id}/members
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3GroupsIdMembers
export def "get-v3-groups-id-members" [
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
  --query: string # A query string to search for members
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}/members"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, query: $query, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a member to a group or project.
#
# POST /v3/groups/{id}/members
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: postV3GroupsIdMembers
export def "post-v3-groups-id-members" [
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
  user_id: int # The user ID of the new member
  access_level: int # A valid access level (defaults: `30`, developer access level)
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/groups/{id}/members"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: user_id, var: user_id}, {name: access_level, var: access_level}, {name: expires_at, var: expires_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level, expires_at: $expires_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a group or project.
#
# DELETE /v3/groups/{id}/members/{user_id}
# operationId: deleteV3GroupsIdMembersUserId
export def "delete-v3-groups-id-members-user-id" [
  id: string
  user_id: int
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
    path: "/v3/groups/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a member of a group or project.
#
# GET /v3/groups/{id}/members/{user_id}
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3GroupsIdMembersUserId
export def "get-v3-groups-id-members-user-id" [
  id: string
  user_id: int
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
    path: "/v3/groups/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a member of a group or project.
#
# PUT /v3/groups/{id}/members/{user_id}
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: putV3GroupsIdMembersUserId
export def "put-v3-groups-id-members-user-id" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  access_level: int # A valid access level
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/groups/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: access_level, var: access_level}, {name: expires_at, var: expires_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level, expires_at: $expires_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group level notification level settings, defaults to Global
#
# GET /v3/groups/{id}/notification_settings
# Returns: record<events: string, level: string>
# operationId: getV3GroupsIdNotificationSettings
export def "get-v3-groups-id-notification-settings" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}/notification_settings"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update group level notification level settings, defaults to Global
#
# PUT /v3/groups/{id}/notification_settings
# Returns: record<events: string, level: string>
# operationId: putV3GroupsIdNotificationSettings
export def "put-v3-groups-id-notification-settings" [
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
  --level: string # The group notification level
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/groups/{id}/notification_settings"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: level, var: level}, {name: new_note, var: new_note}, {name: new_issue, var: new_issue}, {name: reopen_issue, var: reopen_issue}, {name: close_issue, var: close_issue}, {name: reassign_issue, var: reassign_issue}, {name: new_merge_request, var: new_merge_request}, {name: reopen_merge_request, var: reopen_merge_request}, {name: close_merge_request, var: close_merge_request}, {name: reassign_merge_request, var: reassign_merge_request}, {name: merge_merge_request, var: merge_merge_request}, {name: failed_pipeline, var: failed_pipeline}, {name: success_pipeline, var: success_pipeline}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, level: $level, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of projects in this group.
#
# GET /v3/groups/{id}/projects
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: getV3GroupsIdProjects
export def "get-v3-groups-id-projects" [
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
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/groups/{id}/projects"
    path_params: [{name: id, var: id}]
    query: [{name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: simple, var: simple}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, archived: $archived, visibility: $visibility, search: $search, order_by: $order_by, sort: $sort, simple: $simple, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer a project to the group namespace. Available only for admin.
#
# POST /v3/groups/{id}/projects/{project_id}
# Returns: record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string>
# operationId: postV3GroupsIdProjectsProjectId
export def "post-v3-groups-id-projects-project-id" [
  id: string
  project_id: string
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
    path: "/v3/groups/{id}/projects/{project_id}"
    path_params: [{name: id, var: id}, {name: project_id, var: project_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, project_id: $project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of system hooks
#
# GET /v3/hooks
# Returns: record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>
# operationId: getV3Hooks
export def "get-v3-hooks" [
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
    path: "/v3/hooks"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new system hook
#
# POST /v3/hooks
# Returns: record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>
# operationId: postV3Hooks
export def "post-v3-hooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # The URL to send the request to
  --body-token: string # The token used to validate payloads (spec name: token)
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/hooks"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: token, var: body_token}, {name: push_events, var: push_events}, {name: tag_push_events, var: tag_push_events}, {name: enable_ssl_verification, var: enable_ssl_verification}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    url: $url, body_token: $body_token, push_events: $push_events, tag_push_events: $tag_push_events, enable_ssl_verification: $enable_ssl_verification
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a hook
#
# DELETE /v3/hooks/{id}
# Returns: record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>
# operationId: deleteV3HooksId
export def "delete-v3-hooks-id" [
  id: int
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
    method: delete
    path: "/v3/hooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Test a hook
#
# GET /v3/hooks/{id}
# Returns: record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string>
# operationId: getV3HooksId
export def "get-v3-hooks-id" [
  id: int
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
    path: "/v3/hooks/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v3/internal/allowed
#
# operationId: postV3InternalAllowed
export def "post-v3-internal-allowed" [
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
    path: "/v3/internal/allowed"
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/internal/broadcast_message
#
# operationId: getV3InternalBroadcastMessage
export def "get-v3-internal-broadcast-message" [
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
    path: "/v3/internal/broadcast_message"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/internal/check
#
# operationId: getV3InternalCheck
export def "get-v3-internal-check" [
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
    path: "/v3/internal/check"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/internal/discover
#
# operationId: getV3InternalDiscover
export def "get-v3-internal-discover" [
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
    path: "/v3/internal/discover"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v3/internal/lfs_authenticate
#
# operationId: postV3InternalLfsAuthenticate
export def "post-v3-internal-lfs-authenticate" [
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
    path: "/v3/internal/lfs_authenticate"
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /v3/internal/merge_request_urls
#
# operationId: getV3InternalMergeRequestUrls
export def "get-v3-internal-merge-request-urls" [
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
    path: "/v3/internal/merge_request_urls"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /v3/internal/two_factor_recovery_codes
#
# operationId: postV3InternalTwoFactorRecoveryCodes
export def "post-v3-internal-two-factor-recovery-codes" [
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
    path: "/v3/internal/two_factor_recovery_codes"
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get currently authenticated user's issues
#
# GET /v3/issues
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: getV3Issues
export def "get-v3-issues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Return opened, closed, or all issues (default: all)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/issues"
    query: [{name: state, var: state}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    state: $state, labels: $labels, milestone: $milestone, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get single ssh key by id. Only available to admin users
#
# GET /v3/keys/{id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string, user: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>>
# operationId: getV3KeysId
export def "get-v3-keys-id" [
  id: int
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
    path: "/v3/keys/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available license template
#
# GET /v3/licenses
# Returns: record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>
# operationId: getV3Licenses
export def "get-v3-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --popular: oneof<nothing, bool> # If passed, returns only popular licenses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/licenses"
    query: [{name: popular, var: popular}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    popular: $popular
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific license
#
# GET /v3/licenses/{name}
# Returns: record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>
# operationId: getV3LicensesName
export def "get-v3-licenses-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/licenses/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a namespaces list
#
# GET /v3/namespaces
# Returns: record<id: string, kind: string, name: string, path: string>
# operationId: getV3Namespaces
export def "get-v3-namespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search query for namespaces
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/namespaces"
    query: [{name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    search: $search, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get global notification level settings and email, defaults to Participate
#
# GET /v3/notification_settings
# Returns: record<events: string, level: string, notification_email: string>
# operationId: getV3NotificationSettings
export def "get-v3-notification-settings" [
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
    path: "/v3/notification_settings"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update global notification level settings and email, defaults to Participate
#
# PUT /v3/notification_settings
# Returns: record<events: string, level: string, notification_email: string>
# operationId: putV3NotificationSettings
export def "put-v3-notification-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # The global notification level
  --notification-email: string # The email address to send notifications
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/notification_settings"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: level, var: level}, {name: notification_email, var: notification_email}, {name: new_note, var: new_note}, {name: new_issue, var: new_issue}, {name: reopen_issue, var: reopen_issue}, {name: close_issue, var: close_issue}, {name: reassign_issue, var: reassign_issue}, {name: new_merge_request, var: new_merge_request}, {name: reopen_merge_request, var: reopen_merge_request}, {name: close_merge_request, var: close_merge_request}, {name: reassign_merge_request, var: reassign_merge_request}, {name: merge_merge_request, var: merge_merge_request}, {name: failed_pipeline, var: failed_pipeline}, {name: success_pipeline, var: success_pipeline}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    level: $level, notification_email: $notification_email, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a projects list for authenticated user
#
# GET /v3/projects
# Returns: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>
# operationId: getV3Projects
export def "get-v3-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects"
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}, {name: simple, var: simple}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    order_by: $order_by, sort: $sort, archived: $archived, visibility: $visibility, search: $search, page: $page, per_page: $per_page, simple: $simple
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new project
#
# POST /v3/projects
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3Projects
export def "post-v3-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project
  --path: string # The path of the repository
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
  --namespace-id: int # Namespace ID for the new project. Default to the user namespace.
  --import-url: string # URL from which the project is imported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: path, var: path}, {name: description, var: description}, {name: issues_enabled, var: issues_enabled}, {name: merge_requests_enabled, var: merge_requests_enabled}, {name: wiki_enabled, var: wiki_enabled}, {name: builds_enabled, var: builds_enabled}, {name: snippets_enabled, var: snippets_enabled}, {name: shared_runners_enabled, var: shared_runners_enabled}, {name: container_registry_enabled, var: container_registry_enabled}, {name: lfs_enabled, var: lfs_enabled}, {name: public, var: public}, {name: visibility_level, var: visibility_level}, {name: public_builds, var: public_builds}, {name: request_access_enabled, var: request_access_enabled}, {name: only_allow_merge_if_build_succeeds, var: only_allow_merge_if_build_succeeds}, {name: only_allow_merge_if_all_discussions_are_resolved, var: only_allow_merge_if_all_discussions_are_resolved}, {name: namespace_id, var: namespace_id}, {name: import_url, var: import_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    name: $name, path: $path, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved, namespace_id: $namespace_id, import_url: $import_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all projects for admin user
#
# GET /v3/projects/all
# Returns: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>
# operationId: getV3ProjectsAll
export def "get-v3-projects-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/all"
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}, {name: simple, var: simple}, {name: statistics, var: statistics}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    order_by: $order_by, sort: $sort, archived: $archived, visibility: $visibility, search: $search, page: $page, per_page: $per_page, simple: $simple, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Fork new project for the current user or provided namespace.
#
# POST /v3/projects/fork/{id}
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3ProjectsForkId
export def "post-v3-projects-fork-id" [
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
  --namespace: string # The ID or name of the namespace that the project will be forked into
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/fork/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: namespace, var: namespace}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, namespace: $namespace
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an owned projects list for authenticated user
#
# GET /v3/projects/owned
# Returns: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>
# operationId: getV3ProjectsOwned
export def "get-v3-projects-owned" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/owned"
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}, {name: simple, var: simple}, {name: statistics, var: statistics}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    order_by: $order_by, sort: $sort, archived: $archived, visibility: $visibility, search: $search, page: $page, per_page: $per_page, simple: $simple, statistics: $statistics
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search for projects the current user has access to
#
# GET /v3/projects/search/{query}
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: getV3ProjectsSearchQuery
export def "get-v3-projects-search-query" [
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
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/search/{query}"
    path_params: [{name: query, var: query}]
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    query: $query, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets starred project for the authenticated user
#
# GET /v3/projects/starred
# Returns: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>
# operationId: getV3ProjectsStarred
export def "get-v3-projects-starred" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/starred"
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}, {name: simple, var: simple}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    order_by: $order_by, sort: $sort, archived: $archived, visibility: $visibility, search: $search, page: $page, per_page: $per_page, simple: $simple
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new project for a specified user. Only available to admin users.
#
# POST /v3/projects/user/{user_id}
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3ProjectsUserUserId
export def "post-v3-projects-user-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project
  --default-branch: string # The default branch of the project
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
  --namespace-id: int # Namespace ID for the new project. Default to the user namespace.
  --import-url: string # URL from which the project is imported
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/user/{user_id}"
    path_params: [{name: user_id, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: default_branch, var: default_branch}, {name: description, var: description}, {name: issues_enabled, var: issues_enabled}, {name: merge_requests_enabled, var: merge_requests_enabled}, {name: wiki_enabled, var: wiki_enabled}, {name: builds_enabled, var: builds_enabled}, {name: snippets_enabled, var: snippets_enabled}, {name: shared_runners_enabled, var: shared_runners_enabled}, {name: container_registry_enabled, var: container_registry_enabled}, {name: lfs_enabled, var: lfs_enabled}, {name: public, var: public}, {name: visibility_level, var: visibility_level}, {name: public_builds, var: public_builds}, {name: request_access_enabled, var: request_access_enabled}, {name: only_allow_merge_if_build_succeeds, var: only_allow_merge_if_build_succeeds}, {name: only_allow_merge_if_all_discussions_are_resolved, var: only_allow_merge_if_all_discussions_are_resolved}, {name: namespace_id, var: namespace_id}, {name: import_url, var: import_url}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    user_id: $user_id, name: $name, default_branch: $default_branch, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved, namespace_id: $namespace_id, import_url: $import_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of visible projects for authenticated user
#
# GET /v3/projects/visible
# Returns: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>
# operationId: getV3ProjectsVisible
export def "get-v3-projects-visible" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/visible"
    query: [{name: order_by, var: order_by}, {name: sort, var: sort}, {name: archived, var: archived}, {name: visibility, var: visibility}, {name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}, {name: simple, var: simple}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    order_by: $order_by, sort: $sort, archived: $archived, visibility: $visibility, search: $search, page: $page, per_page: $per_page, simple: $simple
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a project
#
# DELETE /v3/projects/{id}
# operationId: deleteV3ProjectsId
export def "delete-v3-projects-id" [
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
    path: "/v3/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single project
#
# GET /v3/projects/{id}
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, permissions: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: getV3ProjectsId
export def "get-v3-projects-id" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing project
#
# PUT /v3/projects/{id}
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: putV3ProjectsId
export def "put-v3-projects-id" [
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
  --name: string # The name of the project
  --default-branch: string # The default branch of the project
  --path: string # The path of the repository
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: default_branch, var: default_branch}, {name: path, var: path}, {name: description, var: description}, {name: issues_enabled, var: issues_enabled}, {name: merge_requests_enabled, var: merge_requests_enabled}, {name: wiki_enabled, var: wiki_enabled}, {name: builds_enabled, var: builds_enabled}, {name: snippets_enabled, var: snippets_enabled}, {name: shared_runners_enabled, var: shared_runners_enabled}, {name: container_registry_enabled, var: container_registry_enabled}, {name: lfs_enabled, var: lfs_enabled}, {name: public, var: public}, {name: visibility_level, var: visibility_level}, {name: public_builds, var: public_builds}, {name: request_access_enabled, var: request_access_enabled}, {name: only_allow_merge_if_build_succeeds, var: only_allow_merge_if_build_succeeds}, {name: only_allow_merge_if_all_discussions_are_resolved, var: only_allow_merge_if_all_discussions_are_resolved}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, name: $name, default_branch: $default_branch, path: $path, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a GitLab project build
#
# POST /v3/projects/{id}/(ref/{ref}/)trigger/builds
# Returns: record<id: string, variables: string>
# operationId: postV3ProjectsId(refRef)triggerBuilds
export def "post-v3-projects-idref-reftrigger-builds" [
  id: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The unique token of trigger (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/(ref/{ref}/)trigger/builds"
    path_params: [{name: id, var: id}, {name: ref, var: ref}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, ref: $ref, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of access requests for a project.
#
# GET /v3/projects/{id}/access_requests
# Returns: record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>
# operationId: getV3ProjectsIdAccessRequests
export def "get-v3-projects-id-access-requests" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/access_requests"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Requests access for the authenticated user to a project.
#
# POST /v3/projects/{id}/access_requests
# Returns: record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string>
# operationId: postV3ProjectsIdAccessRequests
export def "post-v3-projects-id-access-requests" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/projects/{id}/access_requests"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Denies an access request for the given user.
#
# DELETE /v3/projects/{id}/access_requests/{user_id}
# operationId: deleteV3ProjectsIdAccessRequestsUserId
export def "delete-v3-projects-id-access-requests-user-id" [
  id: string
  user_id: int
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
    path: "/v3/projects/{id}/access_requests/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Approves an access request for the given user.
#
# PUT /v3/projects/{id}/access_requests/{user_id}/approve
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: putV3ProjectsIdAccessRequestsUserIdApprove
export def "put-v3-projects-id-access-requests-user-id-approve" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-level: int # A valid access level (defaults: `30`, developer access level)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/access_requests/{user_id}/approve"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: access_level, var: access_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Archive a project
#
# POST /v3/projects/{id}/archive
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3ProjectsIdArchive
export def "post-v3-projects-id-archive" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/projects/{id}/archive"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all project boards
#
# GET /v3/projects/{id}/boards
# Returns: record<id: string, lists: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>>
# operationId: getV3ProjectsIdBoards
export def "get-v3-projects-id-boards" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/boards"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the lists of a project board
#
# GET /v3/projects/{id}/boards/{board_id}/lists
# Returns: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>
# operationId: getV3ProjectsIdBoardsBoardIdLists
export def "get-v3-projects-id-boards-board-id-lists" [
  id: string
  board_id: int
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
    path: "/v3/projects/{id}/boards/{board_id}/lists"
    path_params: [{name: id, var: id}, {name: board_id, var: board_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, board_id: $board_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new board list
#
# POST /v3/projects/{id}/boards/{board_id}/lists
# Returns: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>
# operationId: postV3ProjectsIdBoardsBoardIdLists
export def "post-v3-projects-id-boards-board-id-lists" [
  id: string
  board_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label_id: int # The ID of an existing label
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/boards/{board_id}/lists"
    path_params: [{name: id, var: id}, {name: board_id, var: board_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: label_id, var: label_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, board_id: $board_id, label_id: $label_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a board list
#
# DELETE /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# Returns: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>
# operationId: deleteV3ProjectsIdBoardsBoardIdListsListId
export def "delete-v3-projects-id-boards-board-id-lists-list-id" [
  id: string
  board_id: int
  list_id: int
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
    method: delete
    path: "/v3/projects/{id}/boards/{board_id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: board_id, var: board_id}, {name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, board_id: $board_id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of a project board
#
# GET /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# Returns: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>
# operationId: getV3ProjectsIdBoardsBoardIdListsListId
export def "get-v3-projects-id-boards-board-id-lists-list-id" [
  id: string
  board_id: int
  list_id: int
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
    path: "/v3/projects/{id}/boards/{board_id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: board_id, var: board_id}, {name: list_id, var: list_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, board_id: $board_id, list_id: $list_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Moves a board list to a new position
#
# PUT /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# Returns: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>
# operationId: putV3ProjectsIdBoardsBoardIdListsListId
export def "put-v3-projects-id-boards-board-id-lists-list-id" [
  id: string
  board_id: int
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  position: int # The position of the list
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/boards/{board_id}/lists/{list_id}"
    path_params: [{name: id, var: id}, {name: board_id, var: board_id}, {name: list_id, var: list_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: position, var: position}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, board_id: $board_id, list_id: $list_id, position: $position
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project builds
#
# GET /v3/projects/{id}/builds
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: getV3ProjectsIdBuilds
export def "get-v3-projects-id-builds" [
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
  --scope: string@scope-completer # The scope of builds to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/builds"
    path_params: [{name: id, var: id}]
    query: [{name: scope, var: scope}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, scope: $scope, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the artifacts file from build
#
# GET /v3/projects/{id}/builds/artifacts/{ref_name}/download
# operationId: getV3ProjectsIdBuildsArtifactsRefNameDownload
export def "get-v3-projects-id-builds-artifacts-ref-name-download" [
  id: string
  ref_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job: string # The name for the build (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/projects/{id}/builds/artifacts/{ref_name}/download"
    path_params: [{name: id, var: id}, {name: ref_name, var: ref_name}]
    query: [{name: job, var: job, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, ref_name: $ref_name, job: $job
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific build of a project
#
# GET /v3/projects/{id}/builds/{build_id}
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: getV3ProjectsIdBuildsBuildId
export def "get-v3-projects-id-builds-build-id" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download the artifacts file from build
#
# GET /v3/projects/{id}/builds/{build_id}/artifacts
# operationId: getV3ProjectsIdBuildsBuildIdArtifacts
export def "get-v3-projects-id-builds-build-id-artifacts" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/artifacts"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Keep the artifacts to prevent them from being deleted
#
# POST /v3/projects/{id}/builds/{build_id}/artifacts/keep
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: postV3ProjectsIdBuildsBuildIdArtifactsKeep
export def "post-v3-projects-id-builds-build-id-artifacts-keep" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/artifacts/keep"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a specific build of a project
#
# POST /v3/projects/{id}/builds/{build_id}/cancel
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: postV3ProjectsIdBuildsBuildIdCancel
export def "post-v3-projects-id-builds-build-id-cancel" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/cancel"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Erase build (remove artifacts and build trace)
#
# POST /v3/projects/{id}/builds/{build_id}/erase
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: postV3ProjectsIdBuildsBuildIdErase
export def "post-v3-projects-id-builds-build-id-erase" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/erase"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a manual build
#
# POST /v3/projects/{id}/builds/{build_id}/play
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: postV3ProjectsIdBuildsBuildIdPlay
export def "post-v3-projects-id-builds-build-id-play" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/play"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retry a specific build of a project
#
# POST /v3/projects/{id}/builds/{build_id}/retry
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: postV3ProjectsIdBuildsBuildIdRetry
export def "post-v3-projects-id-builds-build-id-retry" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/retry"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a trace of a specific build of a project
#
# GET /v3/projects/{id}/builds/{build_id}/trace
# operationId: getV3ProjectsIdBuildsBuildIdTrace
export def "get-v3-projects-id-builds-build-id-trace" [
  id: string
  build_id: int
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
    path: "/v3/projects/{id}/builds/{build_id}/trace"
    path_params: [{name: id, var: id}, {name: build_id, var: build_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, build_id: $build_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific project's deploy keys
#
# GET /v3/projects/{id}/deploy_keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3ProjectsIdDeployKeys
export def "get-v3-projects-id-deploy-keys" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/deploy_keys"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new deploy key to currently authenticated user
#
# POST /v3/projects/{id}/deploy_keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3ProjectsIdDeployKeys
export def "post-v3-projects-id-deploy-keys" [
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
  key: string # The new deploy key
  title: string # The name of the deploy key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/deploy_keys"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: key, var: key}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key: $key, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete deploy key for a project
#
# DELETE /v3/projects/{id}/deploy_keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3ProjectsIdDeployKeysKeyId
export def "delete-v3-projects-id-deploy-keys-key-id" [
  id: string
  key_id: int
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
    method: delete
    path: "/v3/projects/{id}/deploy_keys/{key_id}"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get single deploy key
#
# GET /v3/projects/{id}/deploy_keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3ProjectsIdDeployKeysKeyId
export def "get-v3-projects-id-deploy-keys-key-id" [
  id: string
  key_id: int
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
    path: "/v3/projects/{id}/deploy_keys/{key_id}"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a deploy key for a project
#
# DELETE /v3/projects/{id}/deploy_keys/{key_id}/disable
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3ProjectsIdDeployKeysKeyIdDisable
export def "delete-v3-projects-id-deploy-keys-key-id-disable" [
  id: string
  key_id: int
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
    method: delete
    path: "/v3/projects/{id}/deploy_keys/{key_id}/disable"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a deploy key for a project
#
# POST /v3/projects/{id}/deploy_keys/{key_id}/enable
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3ProjectsIdDeployKeysKeyIdEnable
export def "post-v3-projects-id-deploy-keys-key-id-enable" [
  id: string
  key_id: int
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
    path: "/v3/projects/{id}/deploy_keys/{key_id}/enable"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all deployments of the project
#
# GET /v3/projects/{id}/deployments
# Returns: record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdDeployments
export def "get-v3-projects-id-deployments" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/deployments"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific deployment
#
# GET /v3/projects/{id}/deployments/{deployment_id}
# Returns: record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdDeploymentsDeploymentId
export def "get-v3-projects-id-deployments-deployment-id" [
  id: string
  deployment_id: int
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
    path: "/v3/projects/{id}/deployments/{deployment_id}"
    path_params: [{name: id, var: id}, {name: deployment_id, var: deployment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, deployment_id: $deployment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all environments of the project
#
# GET /v3/projects/{id}/environments
# Returns: record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>
# operationId: getV3ProjectsIdEnvironments
export def "get-v3-projects-id-environments" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/environments"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new environment
#
# POST /v3/projects/{id}/environments
# Returns: record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>
# operationId: postV3ProjectsIdEnvironments
export def "post-v3-projects-id-environments" [
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
  name: string # The name of the environment to be created
  --external-url: string # URL on which this deployment is viewable
  --slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/environments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: external_url, var: external_url}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, name: $name, external_url: $external_url, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes an existing environment
#
# DELETE /v3/projects/{id}/environments/{environment_id}
# Returns: record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>
# operationId: deleteV3ProjectsIdEnvironmentsEnvironmentId
export def "delete-v3-projects-id-environments-environment-id" [
  id: string
  environment_id: int
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
    method: delete
    path: "/v3/projects/{id}/environments/{environment_id}"
    path_params: [{name: id, var: id}, {name: environment_id, var: environment_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, environment_id: $environment_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates an existing environment
#
# PUT /v3/projects/{id}/environments/{environment_id}
# Returns: record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string>
# operationId: putV3ProjectsIdEnvironmentsEnvironmentId
export def "put-v3-projects-id-environments-environment-id" [
  id: string
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new environment name
  --external-url: string # The new URL on which this deployment is viewable
  --slug: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/environments/{environment_id}"
    path_params: [{name: id, var: id}, {name: environment_id, var: environment_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: external_url, var: external_url}, {name: slug, var: slug}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, environment_id: $environment_id, name: $name, external_url: $external_url, slug: $slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get events for a single project
#
# GET /v3/projects/{id}/events
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string>
# operationId: getV3ProjectsIdEvents
export def "get-v3-projects-id-events" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a forked_from relationship
#
# DELETE /v3/projects/{id}/fork
# operationId: deleteV3ProjectsIdFork
export def "delete-v3-projects-id-fork" [
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
    path: "/v3/projects/{id}/fork"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark this project as forked from another
#
# POST /v3/projects/{id}/fork/{forked_from_id}
# operationId: postV3ProjectsIdForkForkedFromId
export def "post-v3-projects-id-fork-forked-from-id" [
  id: string
  forked_from_id: string
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
    path: "/v3/projects/{id}/fork/{forked_from_id}"
    path_params: [{name: id, var: id}, {name: forked_from_id, var: forked_from_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, forked_from_id: $forked_from_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project hooks
#
# GET /v3/projects/{id}/hooks
# Returns: record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>
# operationId: getV3ProjectsIdHooks
export def "get-v3-projects-id-hooks" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/hooks"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add hook to project
#
# POST /v3/projects/{id}/hooks
# Returns: record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>
# operationId: postV3ProjectsIdHooks
export def "post-v3-projects-id-hooks" [
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
  url: string # The URL to send the request to
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --issues-events: oneof<nothing, bool> # Trigger hook on issues events
  --merge-requests-events: oneof<nothing, bool> # Trigger hook on merge request events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --note-events: oneof<nothing, bool> # Trigger hook on note(comment) events
  --build-events: oneof<nothing, bool> # Trigger hook on build events
  --pipeline-events: oneof<nothing, bool> # Trigger hook on pipeline events
  --wiki-page-events: oneof<nothing, bool> # Trigger hook on wiki events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
  --body-token: string # Secret token to validate received payloads; this will not be returned in the response (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/hooks"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: push_events, var: push_events}, {name: issues_events, var: issues_events}, {name: merge_requests_events, var: merge_requests_events}, {name: tag_push_events, var: tag_push_events}, {name: note_events, var: note_events}, {name: build_events, var: build_events}, {name: pipeline_events, var: pipeline_events}, {name: wiki_page_events, var: wiki_page_events}, {name: enable_ssl_verification, var: enable_ssl_verification}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, url: $url, push_events: $push_events, issues_events: $issues_events, merge_requests_events: $merge_requests_events, tag_push_events: $tag_push_events, note_events: $note_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events, enable_ssl_verification: $enable_ssl_verification, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes project hook
#
# DELETE /v3/projects/{id}/hooks/{hook_id}
# Returns: record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>
# operationId: deleteV3ProjectsIdHooksHookId
export def "delete-v3-projects-id-hooks-hook-id" [
  id: string
  hook_id: int
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
    method: delete
    path: "/v3/projects/{id}/hooks/{hook_id}"
    path_params: [{name: id, var: id}, {name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project hook
#
# GET /v3/projects/{id}/hooks/{hook_id}
# Returns: record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>
# operationId: getV3ProjectsIdHooksHookId
export def "get-v3-projects-id-hooks-hook-id" [
  id: string
  hook_id: int
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
    path: "/v3/projects/{id}/hooks/{hook_id}"
    path_params: [{name: id, var: id}, {name: hook_id, var: hook_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, hook_id: $hook_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing project hook
#
# PUT /v3/projects/{id}/hooks/{hook_id}
# Returns: record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string>
# operationId: putV3ProjectsIdHooksHookId
export def "put-v3-projects-id-hooks-hook-id" [
  id: string
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # The URL to send the request to
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --issues-events: oneof<nothing, bool> # Trigger hook on issues events
  --merge-requests-events: oneof<nothing, bool> # Trigger hook on merge request events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --note-events: oneof<nothing, bool> # Trigger hook on note(comment) events
  --build-events: oneof<nothing, bool> # Trigger hook on build events
  --pipeline-events: oneof<nothing, bool> # Trigger hook on pipeline events
  --wiki-page-events: oneof<nothing, bool> # Trigger hook on wiki events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
  --body-token: string # Secret token to validate received payloads; this will not be returned in the response (spec name: token)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/hooks/{hook_id}"
    path_params: [{name: id, var: id}, {name: hook_id, var: hook_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: push_events, var: push_events}, {name: issues_events, var: issues_events}, {name: merge_requests_events, var: merge_requests_events}, {name: tag_push_events, var: tag_push_events}, {name: note_events, var: note_events}, {name: build_events, var: build_events}, {name: pipeline_events, var: pipeline_events}, {name: wiki_page_events, var: wiki_page_events}, {name: enable_ssl_verification, var: enable_ssl_verification}, {name: token, var: body_token}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, hook_id: $hook_id, url: $url, push_events: $push_events, issues_events: $issues_events, merge_requests_events: $merge_requests_events, tag_push_events: $tag_push_events, note_events: $note_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events, enable_ssl_verification: $enable_ssl_verification, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project issues
#
# GET /v3/projects/{id}/issues
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: getV3ProjectsIdIssues
export def "get-v3-projects-id-issues" [
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
  --state: string@state-completer # Return opened, closed, or all issues (default: all)
  --iid: int # Return the issue having the given `iid` (format: int32)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/issues"
    path_params: [{name: id, var: id}]
    query: [{name: state, var: state}, {name: iid, var: iid}, {name: labels, var: labels}, {name: milestone, var: milestone}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, state: $state, iid: $iid, labels: $labels, milestone: $milestone, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project issue
#
# POST /v3/projects/{id}/issues
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: postV3ProjectsIdIssues
export def "post-v3-projects-id-issues" [
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
  title: string # The title of an issue
  --created-at: string # Date time when the issue was created. Available only for admins and project owners.
  --merge-request-for-resolving-discussions: int # The IID of a merge request for which to resolve discussions
  --description: string # The description of an issue
  --assignee-id: int # The ID of a user to assign issue
  --milestone-id: int # The ID of a milestone to assign issue
  --labels: string # Comma-separated list of label names
  --due-date: string # Date time string in the format YEAR-MONTH-DAY
  --confidential: oneof<nothing, bool> # Boolean parameter if the issue should be confidential
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: created_at, var: created_at}, {name: merge_request_for_resolving_discussions, var: merge_request_for_resolving_discussions}, {name: description, var: description}, {name: assignee_id, var: assignee_id}, {name: milestone_id, var: milestone_id}, {name: labels, var: labels}, {name: due_date, var: due_date}, {name: confidential, var: confidential}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, title: $title, created_at: $created_at, merge_request_for_resolving_discussions: $merge_request_for_resolving_discussions, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, due_date: $due_date, confidential: $confidential
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project issue
#
# DELETE /v3/projects/{id}/issues/{issue_id}
# operationId: deleteV3ProjectsIdIssuesIssueId
export def "delete-v3-projects-id-issues-issue-id" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single project issue
#
# GET /v3/projects/{id}/issues/{issue_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: getV3ProjectsIdIssuesIssueId
export def "get-v3-projects-id-issues-issue-id" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing issue
#
# PUT /v3/projects/{id}/issues/{issue_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: putV3ProjectsIdIssuesIssueId
export def "put-v3-projects-id-issues-issue-id" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of an issue
  --updated-at: string # Date time when the issue was updated. Available only for admins and project owners.
  --state-event: string@state-event-completer # State of the issue
  --description: string # The description of an issue
  --assignee-id: int # The ID of a user to assign issue
  --milestone-id: int # The ID of a milestone to assign issue
  --labels: string # Comma-separated list of label names
  --due-date: string # Date time string in the format YEAR-MONTH-DAY
  --confidential: oneof<nothing, bool> # Boolean parameter if the issue should be confidential
  --created-at: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/issues/{issue_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: updated_at, var: updated_at}, {name: state_event, var: state_event}, {name: description, var: description}, {name: assignee_id, var: assignee_id}, {name: milestone_id, var: milestone_id}, {name: labels, var: labels}, {name: due_date, var: due_date}, {name: confidential, var: confidential}, {name: created_at, var: created_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, title: $title, updated_at: $updated_at, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, due_date: $due_date, confidential: $confidential, created_at: $created_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add spent time for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/add_spent_time
# operationId: postV3ProjectsIdIssuesIssueIdAddSpentTime
export def "post-v3-projects-id-issues-issue-id-add-spent-time" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{issue_id}/add_spent_time"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: duration, var: duration}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, duration: $duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdIssuesIssueIdAwardEmoji
export def "get-v3-projects-id-issues-issue-id-award-emoji" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/issues/{issue_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/issues/{issue_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdIssuesIssueIdAwardEmoji
export def "post-v3-projects-id-issues-issue-id-award-emoji" [
  id: int
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{issue_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdIssuesIssueIdAwardEmojiAwardId
export def "delete-v3-projects-id-issues-issue-id-award-emoji-award-id" [
  id: int
  issue_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdIssuesIssueIdAwardEmojiAwardId
export def "get-v3-projects-id-issues-issue-id-award-emoji-award-id" [
  id: int
  issue_id: int
  award_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Move an existing issue
#
# POST /v3/projects/{id}/issues/{issue_id}/move
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: postV3ProjectsIdIssuesIssueIdMove
export def "post-v3-projects-id-issues-issue-id-move" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  to_project_id: int # The ID of the new project
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{issue_id}/move"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: to_project_id, var: to_project_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, to_project_id: $to_project_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmoji
export def "get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji" [
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: note_id, var: note_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, note_id: $note_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmoji
export def "post-v3-projects-id-issues-issue-id-notes-note-id-award-emoji" [
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, note_id: $note_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmojiAwardId
export def "delete-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id" [
  id: int
  issue_id: int
  note_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmojiAwardId
export def "get-v3-projects-id-issues-issue-id-notes-note-id-award-emoji-award-id" [
  id: int
  issue_id: int
  note_id: int
  award_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset spent time for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/reset_spent_time
# operationId: postV3ProjectsIdIssuesIssueIdResetSpentTime
export def "post-v3-projects-id-issues-issue-id-reset-spent-time" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/reset_spent_time"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the time estimate for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/reset_time_estimate
# operationId: postV3ProjectsIdIssuesIssueIdResetTimeEstimate
export def "post-v3-projects-id-issues-issue-id-reset-time-estimate" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/reset_time_estimate"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a time estimate for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/time_estimate
# operationId: postV3ProjectsIdIssuesIssueIdTimeEstimate
export def "post-v3-projects-id-issues-issue-id-time-estimate" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{issue_id}/time_estimate"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: duration, var: duration}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id, duration: $duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show time stats for a project issue
#
# GET /v3/projects/{id}/issues/{issue_id}/time_stats
# operationId: getV3ProjectsIdIssuesIssueIdTimeStats
export def "get-v3-projects-id-issues-issue-id-time-stats" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/time_stats"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a todo on an issuable
#
# POST /v3/projects/{id}/issues/{issue_id}/todo
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>
# operationId: postV3ProjectsIdIssuesIssueIdTodo
export def "post-v3-projects-id-issues-issue-id-todo" [
  id: string
  issue_id: int
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
    path: "/v3/projects/{id}/issues/{issue_id}/todo"
    path_params: [{name: id, var: id}, {name: issue_id, var: issue_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, issue_id: $issue_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/issues/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdIssuesNoteableIdNotes
export def "get-v3-projects-id-issues-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/issues/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/issues/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: postV3ProjectsIdIssuesNoteableIdNotes
export def "post-v3-projects-id-issues-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/issues/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}, {name: created_at, var: created_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, body: $body, created_at: $created_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: deleteV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "delete-v3-projects-id-issues-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    method: delete
    path: "/v3/projects/{id}/issues/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "get-v3-projects-id-issues-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    path: "/v3/projects/{id}/issues/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: putV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "put-v3-projects-id-issues-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/issues/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/issues/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: deleteV3ProjectsIdIssuesSubscribableIdSubscription
export def "delete-v3-projects-id-issues-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    method: delete
    path: "/v3/projects/{id}/issues/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/issues/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: postV3ProjectsIdIssuesSubscribableIdSubscription
export def "post-v3-projects-id-issues-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    path: "/v3/projects/{id}/issues/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific project's deploy keys
#
# GET /v3/projects/{id}/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3ProjectsIdKeys
export def "get-v3-projects-id-keys" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/keys"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new deploy key to currently authenticated user
#
# POST /v3/projects/{id}/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3ProjectsIdKeys
export def "post-v3-projects-id-keys" [
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
  key: string # The new deploy key
  title: string # The name of the deploy key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/keys"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: key, var: key}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key: $key, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete deploy key for a project
#
# DELETE /v3/projects/{id}/keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3ProjectsIdKeysKeyId
export def "delete-v3-projects-id-keys-key-id" [
  id: string
  key_id: int
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
    method: delete
    path: "/v3/projects/{id}/keys/{key_id}"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get single deploy key
#
# GET /v3/projects/{id}/keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3ProjectsIdKeysKeyId
export def "get-v3-projects-id-keys-key-id" [
  id: string
  key_id: int
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
    path: "/v3/projects/{id}/keys/{key_id}"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable a deploy key for a project
#
# DELETE /v3/projects/{id}/keys/{key_id}/disable
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3ProjectsIdKeysKeyIdDisable
export def "delete-v3-projects-id-keys-key-id-disable" [
  id: string
  key_id: int
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
    method: delete
    path: "/v3/projects/{id}/keys/{key_id}/disable"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a deploy key for a project
#
# POST /v3/projects/{id}/keys/{key_id}/enable
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3ProjectsIdKeysKeyIdEnable
export def "post-v3-projects-id-keys-key-id-enable" [
  id: string
  key_id: int
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
    path: "/v3/projects/{id}/keys/{key_id}/enable"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing label
#
# DELETE /v3/projects/{id}/labels
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: deleteV3ProjectsIdLabels
export def "delete-v3-projects-id-labels" [
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
  --name: string # The name of the label to be deleted (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v3/projects/{id}/labels"
    path_params: [{name: id, var: id}]
    query: [{name: name, var: name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all labels of the project
#
# GET /v3/projects/{id}/labels
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: getV3ProjectsIdLabels
export def "get-v3-projects-id-labels" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/labels"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new label
#
# POST /v3/projects/{id}/labels
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: postV3ProjectsIdLabels
export def "post-v3-projects-id-labels" [
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
  name: string # The name of the label to be created
  color: string # The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)
  --description: string # The description of label to be created
  --priority: int # The priority of the label
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/labels"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: color, var: color}, {name: description, var: description}, {name: priority, var: priority}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, name: $name, color: $color, description: $description, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing label. At least one optional parameter is required.
#
# PUT /v3/projects/{id}/labels
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: putV3ProjectsIdLabels
export def "put-v3-projects-id-labels" [
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
  name: string # The name of the label to be updated
  --new-name: string # The new name of the label
  --color: string # The new color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)
  --description: string # The new description of label
  --priority: int # The priority of the label
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/labels"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}, {name: new_name, var: new_name}, {name: color, var: color}, {name: description, var: description}, {name: priority, var: priority}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, name: $name, new_name: $new_name, color: $color, description: $description, priority: $priority
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/labels/{subscribable_id}/subscription
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: deleteV3ProjectsIdLabelsSubscribableIdSubscription
export def "delete-v3-projects-id-labels-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    method: delete
    path: "/v3/projects/{id}/labels/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/labels/{subscribable_id}/subscription
# Returns: record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string>
# operationId: postV3ProjectsIdLabelsSubscribableIdSubscription
export def "post-v3-projects-id-labels-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    path: "/v3/projects/{id}/labels/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a list of group or project members viewable by the authenticated user.
#
# GET /v3/projects/{id}/members
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3ProjectsIdMembers
export def "get-v3-projects-id-members" [
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
  --query: string # A query string to search for members
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/members"
    path_params: [{name: id, var: id}]
    query: [{name: query, var: query}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, query: $query, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Adds a member to a group or project.
#
# POST /v3/projects/{id}/members
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: postV3ProjectsIdMembers
export def "post-v3-projects-id-members" [
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
  user_id: int # The user ID of the new member
  access_level: int # A valid access level (defaults: `30`, developer access level)
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/members"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: user_id, var: user_id}, {name: access_level, var: access_level}, {name: expires_at, var: expires_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level, expires_at: $expires_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Removes a user from a group or project.
#
# DELETE /v3/projects/{id}/members/{user_id}
# operationId: deleteV3ProjectsIdMembersUserId
export def "delete-v3-projects-id-members-user-id" [
  id: string
  user_id: int
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
    path: "/v3/projects/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a member of a group or project.
#
# GET /v3/projects/{id}/members/{user_id}
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3ProjectsIdMembersUserId
export def "get-v3-projects-id-members-user-id" [
  id: string
  user_id: int
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
    path: "/v3/projects/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Updates a member of a group or project.
#
# PUT /v3/projects/{id}/members/{user_id}
# Returns: record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: putV3ProjectsIdMembersUserId
export def "put-v3-projects-id-members-user-id" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  access_level: int # A valid access level
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/members/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: access_level, var: access_level}, {name: expires_at, var: expires_at}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, user_id: $user_id, access_level: $access_level, expires_at: $expires_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: getV3ProjectsIdMergeRequestMergeRequestId
export def "get-v3-projects-id-merge-request-merge-request-id" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_request/{merge_request_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a merge request
#
# PUT /v3/projects/{id}/merge_request/{merge_request_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: putV3ProjectsIdMergeRequestMergeRequestId
export def "put-v3-projects-id-merge-request-merge-request-id" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the merge request
  --target-branch: string # The target branch
  --state-event: string@state-event-completer-1 # Status of the merge request
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/merge_request/{merge_request_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: target_branch, var: target_branch}, {name: state_event, var: state_event}, {name: description, var: description}, {name: assignee_id, var: assignee_id}, {name: milestone_id, var: milestone_id}, {name: labels, var: labels}, {name: remove_source_branch, var: remove_source_branch}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, title: $title, target_branch: $target_branch, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel merge if "Merge When Pipeline Succeeds" is enabled
#
# POST /v3/projects/{id}/merge_request/{merge_request_id}/cancel_merge_when_build_succeeds
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: postV3ProjectsIdMergeRequestMergeRequestIdCancelMergeWhenBuildSucceeds
export def "post-v3-projects-id-merge-request-merge-request-id-cancel-merge-when-build-succeeds" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/cancel_merge_when_build_succeeds"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the merge request changes
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/changes
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdChanges
export def "get-v3-projects-id-merge-request-merge-request-id-changes" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/changes"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List issues that will be closed on merge
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/closes_issues
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdClosesIssues
export def "get-v3-projects-id-merge-request-merge-request-id-closes-issues" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/closes_issues"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the comments of a merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdComments
export def "get-v3-projects-id-merge-request-merge-request-id-comments" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/comments"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a comment to a merge request
#
# POST /v3/projects/{id}/merge_request/{merge_request_id}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: postV3ProjectsIdMergeRequestMergeRequestIdComments
export def "post-v3-projects-id-merge-request-merge-request-id-comments" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/comments"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the commits of a merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/commits
# Returns: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdCommits
export def "get-v3-projects-id-merge-request-merge-request-id-commits" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/commits"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge a merge request
#
# PUT /v3/projects/{id}/merge_request/{merge_request_id}/merge
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: putV3ProjectsIdMergeRequestMergeRequestIdMerge
export def "put-v3-projects-id-merge-request-merge-request-id-merge" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-commit-message: string # Custom merge commit message
  --should-remove-source-branch: oneof<nothing, bool> # When true, the source branch will be deleted if possible
  --merge-when-build-succeeds: oneof<nothing, bool> # When true, this merge request will be merged when the pipeline succeeds
  --sha: string # When present, must have the HEAD SHA of the source branch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/merge_request/{merge_request_id}/merge"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: merge_commit_message, var: merge_commit_message}, {name: should_remove_source_branch, var: should_remove_source_branch}, {name: merge_when_build_succeeds, var: merge_when_build_succeeds}, {name: sha, var: sha}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, merge_commit_message: $merge_commit_message, should_remove_source_branch: $should_remove_source_branch, merge_when_build_succeeds: $merge_when_build_succeeds, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/merge_request/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: deleteV3ProjectsIdMergeRequestSubscribableIdSubscription
export def "delete-v3-projects-id-merge-request-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    method: delete
    path: "/v3/projects/{id}/merge_request/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/merge_request/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: postV3ProjectsIdMergeRequestSubscribableIdSubscription
export def "post-v3-projects-id-merge-request-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    path: "/v3/projects/{id}/merge_request/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List merge requests
#
# GET /v3/projects/{id}/merge_requests
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: getV3ProjectsIdMergeRequests
export def "get-v3-projects-id-merge-requests" [
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
  --state: string@state-completer-1 # Return opened, closed, merged, or all merge requests (default: all)
  --order-by: string@order-by-completer-1 # Return merge requests ordered by `created_at` or `updated_at` fields. (default: created_at)
  --sort: string@sort-completer # Return merge requests sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests"
    path_params: [{name: id, var: id}]
    query: [{name: state, var: state}, {name: order_by, var: order_by}, {name: sort, var: sort}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, state: $state, order_by: $order_by, sort: $sort, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a merge request
#
# POST /v3/projects/{id}/merge_requests
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: postV3ProjectsIdMergeRequests
export def "post-v3-projects-id-merge-requests" [
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
  title: string # The title of the merge request
  source_branch: string # The source branch
  target_branch: string # The target branch
  --target-project-id: int # The target project of the merge request defaults to the :id of the project
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: source_branch, var: source_branch}, {name: target_branch, var: target_branch}, {name: target_project_id, var: target_project_id}, {name: description, var: description}, {name: assignee_id, var: assignee_id}, {name: milestone_id, var: milestone_id}, {name: labels, var: labels}, {name: remove_source_branch, var: remove_source_branch}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, title: $title, source_branch: $source_branch, target_branch: $target_branch, target_project_id: $target_project_id, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a merge request
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestId
export def "delete-v3-projects-id-merge-requests-merge-request-id" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestId
export def "get-v3-projects-id-merge-requests-merge-request-id" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a merge request
#
# PUT /v3/projects/{id}/merge_requests/{merge_request_id}
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: putV3ProjectsIdMergeRequestsMergeRequestId
export def "put-v3-projects-id-merge-requests-merge-request-id" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the merge request
  --target-branch: string # The target branch
  --state-event: string@state-event-completer-1 # Status of the merge request
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: target_branch, var: target_branch}, {name: state_event, var: state_event}, {name: description, var: description}, {name: assignee_id, var: assignee_id}, {name: milestone_id, var: milestone_id}, {name: labels, var: labels}, {name: remove_source_branch, var: remove_source_branch}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, title: $title, target_branch: $target_branch, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add spent time for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/add_spent_time
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdAddSpentTime
export def "post-v3-projects-id-merge-requests-merge-request-id-add-spent-time" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/add_spent_time"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: duration, var: duration}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, duration: $duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdAwardEmoji
export def "get-v3-projects-id-merge-requests-merge-request-id-award-emoji" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdAwardEmoji
export def "post-v3-projects-id-merge-requests-merge-request-id-award-emoji" [
  id: int
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestIdAwardEmojiAwardId
export def "delete-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id" [
  id: int
  merge_request_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdAwardEmojiAwardId
export def "get-v3-projects-id-merge-requests-merge-request-id-award-emoji-award-id" [
  id: int
  merge_request_id: int
  award_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel merge if "Merge When Pipeline Succeeds" is enabled
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/cancel_merge_when_build_succeeds
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdCancelMergeWhenBuildSucceeds
export def "post-v3-projects-id-merge-requests-merge-request-id-cancel-merge-when-build-succeeds" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/cancel_merge_when_build_succeeds"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show the merge request changes
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/changes
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdChanges
export def "get-v3-projects-id-merge-requests-merge-request-id-changes" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/changes"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List issues that will be closed on merge
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/closes_issues
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdClosesIssues
export def "get-v3-projects-id-merge-requests-merge-request-id-closes-issues" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/closes_issues"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the comments of a merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdComments
export def "get-v3-projects-id-merge-requests-merge-request-id-comments" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/comments"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post a comment to a merge request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string>
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdComments
export def "post-v3-projects-id-merge-requests-merge-request-id-comments" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/comments"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: note, var: note}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note: $note
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the commits of a merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/commits
# Returns: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdCommits
export def "get-v3-projects-id-merge-requests-merge-request-id-commits" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/commits"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Merge a merge request
#
# PUT /v3/projects/{id}/merge_requests/{merge_request_id}/merge
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: putV3ProjectsIdMergeRequestsMergeRequestIdMerge
export def "put-v3-projects-id-merge-requests-merge-request-id-merge" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-commit-message: string # Custom merge commit message
  --should-remove-source-branch: oneof<nothing, bool> # When true, the source branch will be deleted if possible
  --merge-when-build-succeeds: oneof<nothing, bool> # When true, this merge request will be merged when the pipeline succeeds
  --sha: string # When present, must have the HEAD SHA of the source branch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/merge"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: merge_commit_message, var: merge_commit_message}, {name: should_remove_source_branch, var: should_remove_source_branch}, {name: merge_when_build_succeeds, var: merge_when_build_succeeds}, {name: sha, var: sha}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, merge_commit_message: $merge_commit_message, should_remove_source_branch: $should_remove_source_branch, merge_when_build_succeeds: $merge_when_build_succeeds, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmoji
export def "get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji" [
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: note_id, var: note_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note_id: $note_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmoji
export def "post-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji" [
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note_id: $note_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmojiAwardId
export def "delete-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id" [
  id: int
  merge_request_id: int
  note_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmojiAwardId
export def "get-v3-projects-id-merge-requests-merge-request-id-notes-note-id-award-emoji-award-id" [
  id: int
  merge_request_id: int
  note_id: int
  award_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset spent time for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/reset_spent_time
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdResetSpentTime
export def "post-v3-projects-id-merge-requests-merge-request-id-reset-spent-time" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/reset_spent_time"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Reset the time estimate for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/reset_time_estimate
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdResetTimeEstimate
export def "post-v3-projects-id-merge-requests-merge-request-id-reset-time-estimate" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/reset_time_estimate"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set a time estimate for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/time_estimate
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdTimeEstimate
export def "post-v3-projects-id-merge-requests-merge-request-id-time-estimate" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/time_estimate"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: duration, var: duration}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, duration: $duration
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show time stats for a project merge_request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/time_stats
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdTimeStats
export def "get-v3-projects-id-merge-requests-merge-request-id-time-stats" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/time_stats"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a todo on an issuable
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/todo
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdTodo
export def "post-v3-projects-id-merge-requests-merge-request-id-todo" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/todo"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of merge request diff versions
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/versions
# Returns: record<base_commit_sha: string, created_at: string, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdVersions
export def "get-v3-projects-id-merge-requests-merge-request-id-versions" [
  id: string
  merge_request_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/versions"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single merge request diff version
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/versions/{version_id}
# Returns: record<base_commit_sha: string, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, created_at: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string>
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdVersionsVersionId
export def "get-v3-projects-id-merge-requests-merge-request-id-versions-version-id" [
  id: string
  merge_request_id: int
  version_id: int
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
    path: "/v3/projects/{id}/merge_requests/{merge_request_id}/versions/{version_id}"
    path_params: [{name: id, var: id}, {name: merge_request_id, var: merge_request_id}, {name: version_id, var: version_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, merge_request_id: $merge_request_id, version_id: $version_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/merge_requests/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdMergeRequestsNoteableIdNotes
export def "get-v3-projects-id-merge-requests-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/merge_requests/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/merge_requests/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: postV3ProjectsIdMergeRequestsNoteableIdNotes
export def "post-v3-projects-id-merge-requests-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/merge_requests/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}, {name: created_at, var: created_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, body: $body, created_at: $created_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: deleteV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "delete-v3-projects-id-merge-requests-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    method: delete
    path: "/v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "get-v3-projects-id-merge-requests-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    path: "/v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: putV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "put-v3-projects-id-merge-requests-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/merge_requests/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: deleteV3ProjectsIdMergeRequestsSubscribableIdSubscription
export def "delete-v3-projects-id-merge-requests-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    method: delete
    path: "/v3/projects/{id}/merge_requests/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/merge_requests/{subscribable_id}/subscription
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string>
# operationId: postV3ProjectsIdMergeRequestsSubscribableIdSubscription
export def "post-v3-projects-id-merge-requests-subscribable-id-subscription" [
  id: string
  subscribable_id: string
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
    path: "/v3/projects/{id}/merge_requests/{subscribable_id}/subscription"
    path_params: [{name: id, var: id}, {name: subscribable_id, var: subscribable_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, subscribable_id: $subscribable_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project milestones
#
# GET /v3/projects/{id}/milestones
# Returns: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>
# operationId: getV3ProjectsIdMilestones
export def "get-v3-projects-id-milestones" [
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
  --state: string@state-completer-2 # Return "active", "closed", or "all" milestones (default: all)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/milestones"
    path_params: [{name: id, var: id}]
    query: [{name: state, var: state}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, state: $state, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project milestone
#
# POST /v3/projects/{id}/milestones
# Returns: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>
# operationId: postV3ProjectsIdMilestones
export def "post-v3-projects-id-milestones" [
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
  title: string # The title of the milestone
  --description: string # The description of the milestone
  --due-date: string # The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)
  --start-date: string # The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/milestones"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: description, var: description}, {name: due_date, var: due_date}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, title: $title, description: $description, due_date: $due_date, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single project milestone
#
# GET /v3/projects/{id}/milestones/{milestone_id}
# Returns: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>
# operationId: getV3ProjectsIdMilestonesMilestoneId
export def "get-v3-projects-id-milestones-milestone-id" [
  id: string
  milestone_id: int
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
    path: "/v3/projects/{id}/milestones/{milestone_id}"
    path_params: [{name: id, var: id}, {name: milestone_id, var: milestone_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, milestone_id: $milestone_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing project milestone
#
# PUT /v3/projects/{id}/milestones/{milestone_id}
# Returns: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>
# operationId: putV3ProjectsIdMilestonesMilestoneId
export def "put-v3-projects-id-milestones-milestone-id" [
  id: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the milestone
  --state-event: string@state-event-completer-2 # The state event of the milestone
  --description: string # The description of the milestone
  --due-date: string # The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)
  --start-date: string # The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/milestones/{milestone_id}"
    path_params: [{name: id, var: id}, {name: milestone_id, var: milestone_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: state_event, var: state_event}, {name: description, var: description}, {name: due_date, var: due_date}, {name: start_date, var: start_date}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, milestone_id: $milestone_id, title: $title, state_event: $state_event, description: $description, due_date: $due_date, start_date: $start_date
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all issues for a single project milestone
#
# GET /v3/projects/{id}/milestones/{milestone_id}/issues
# Returns: record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string>
# operationId: getV3ProjectsIdMilestonesMilestoneIdIssues
export def "get-v3-projects-id-milestones-milestone-id-issues" [
  id: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/milestones/{milestone_id}/issues"
    path_params: [{name: id, var: id}, {name: milestone_id, var: milestone_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, milestone_id: $milestone_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project level notification level settings, defaults to Global
#
# GET /v3/projects/{id}/notification_settings
# Returns: record<events: string, level: string>
# operationId: getV3ProjectsIdNotificationSettings
export def "get-v3-projects-id-notification-settings" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/notification_settings"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update project level notification level settings, defaults to Global
#
# PUT /v3/projects/{id}/notification_settings
# Returns: record<events: string, level: string>
# operationId: putV3ProjectsIdNotificationSettings
export def "put-v3-projects-id-notification-settings" [
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
  --level: string # The project notification level
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/notification_settings"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: level, var: level}, {name: new_note, var: new_note}, {name: new_issue, var: new_issue}, {name: reopen_issue, var: reopen_issue}, {name: close_issue, var: close_issue}, {name: reassign_issue, var: reassign_issue}, {name: new_merge_request, var: new_merge_request}, {name: reopen_merge_request, var: reopen_merge_request}, {name: close_merge_request, var: close_merge_request}, {name: reassign_merge_request, var: reassign_merge_request}, {name: merge_merge_request, var: merge_merge_request}, {name: failed_pipeline, var: failed_pipeline}, {name: success_pipeline, var: success_pipeline}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, level: $level, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new pipeline
#
# POST /v3/projects/{id}/pipeline
# Returns: record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>
# operationId: postV3ProjectsIdPipeline
export def "post-v3-projects-id-pipeline" [
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
  ref: string # Reference
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/pipeline"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: ref, var: ref}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all Pipelines of the project
#
# GET /v3/projects/{id}/pipelines
# Returns: record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>
# operationId: getV3ProjectsIdPipelines
export def "get-v3-projects-id-pipelines" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --scope: string@scope-completer-1 # Either running, branches, or tags
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/pipelines"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}, {name: scope, var: scope}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page, scope: $scope
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets a specific pipeline for the project
#
# GET /v3/projects/{id}/pipelines/{pipeline_id}
# Returns: record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>
# operationId: getV3ProjectsIdPipelinesPipelineId
export def "get-v3-projects-id-pipelines-pipeline-id" [
  id: string
  pipeline_id: int
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
    path: "/v3/projects/{id}/pipelines/{pipeline_id}"
    path_params: [{name: id, var: id}, {name: pipeline_id, var: pipeline_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, pipeline_id: $pipeline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel all builds in the pipeline
#
# POST /v3/projects/{id}/pipelines/{pipeline_id}/cancel
# Returns: record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>
# operationId: postV3ProjectsIdPipelinesPipelineIdCancel
export def "post-v3-projects-id-pipelines-pipeline-id-cancel" [
  id: string
  pipeline_id: int
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
    path: "/v3/projects/{id}/pipelines/{pipeline_id}/cancel"
    path_params: [{name: id, var: id}, {name: pipeline_id, var: pipeline_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, pipeline_id: $pipeline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Retry failed builds in the pipeline
#
# POST /v3/projects/{id}/pipelines/{pipeline_id}/retry
# Returns: record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string>
# operationId: postV3ProjectsIdPipelinesPipelineIdRetry
export def "post-v3-projects-id-pipelines-pipeline-id-retry" [
  id: string
  pipeline_id: int
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
    path: "/v3/projects/{id}/pipelines/{pipeline_id}/retry"
    path_params: [{name: id, var: id}, {name: pipeline_id, var: pipeline_id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, pipeline_id: $pipeline_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an archive of the repository
#
# GET /v3/projects/{id}/repository/archive
# operationId: getV3ProjectsIdRepositoryArchive
export def "get-v3-projects-id-repository-archive" [
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
  --sha: string # The commit sha of the archive to be downloaded
  --format: string # The archive format
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/archive"
    path_params: [{name: id, var: id}]
    query: [{name: sha, var: sha}, {name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a raw file contents
#
# GET /v3/projects/{id}/repository/blobs/{sha}
# operationId: getV3ProjectsIdRepositoryBlobsSha
export def "get-v3-projects-id-repository-blobs-sha" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filepath: string # The path to the file to display (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/blobs/{sha}"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    query: [{name: filepath, var: filepath, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, filepath: $filepath
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project repository branches
#
# GET /v3/projects/{id}/repository/branches
# Returns: record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>
# operationId: getV3ProjectsIdRepositoryBranches
export def "get-v3-projects-id-repository-branches" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/branches"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create branch
#
# POST /v3/projects/{id}/repository/branches
# Returns: record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>
# operationId: postV3ProjectsIdRepositoryBranches
export def "post-v3-projects-id-repository-branches" [
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
  branch_name: string # The name of the branch
  ref: string # Create branch from commit sha or existing branch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/branches"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: branch_name, var: branch_name}, {name: ref, var: ref}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, branch_name: $branch_name, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a branch
#
# DELETE /v3/projects/{id}/repository/branches/{branch}
# operationId: deleteV3ProjectsIdRepositoryBranchesBranch
export def "delete-v3-projects-id-repository-branches-branch" [
  id: string
  branch: string
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
    path: "/v3/projects/{id}/repository/branches/{branch}"
    path_params: [{name: id, var: id}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single branch
#
# GET /v3/projects/{id}/repository/branches/{branch}
# Returns: record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>
# operationId: getV3ProjectsIdRepositoryBranchesBranch
export def "get-v3-projects-id-repository-branches-branch" [
  id: string
  branch: string
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
    path: "/v3/projects/{id}/repository/branches/{branch}"
    path_params: [{name: id, var: id}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Protect a single branch
#
# PUT /v3/projects/{id}/repository/branches/{branch}/protect
# Returns: record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>
# operationId: putV3ProjectsIdRepositoryBranchesBranchProtect
export def "put-v3-projects-id-repository-branches-branch-protect" [
  id: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --developers-can-push: oneof<nothing, bool> # Flag if developers can push to that branch
  --developers-can-merge: oneof<nothing, bool> # Flag if developers can merge to that branch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/repository/branches/{branch}/protect"
    path_params: [{name: id, var: id}, {name: branch, var: branch}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: developers_can_push, var: developers_can_push}, {name: developers_can_merge, var: developers_can_merge}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, branch: $branch, developers_can_push: $developers_can_push, developers_can_merge: $developers_can_merge
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unprotect a single branch
#
# PUT /v3/projects/{id}/repository/branches/{branch}/unprotect
# Returns: record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string>
# operationId: putV3ProjectsIdRepositoryBranchesBranchUnprotect
export def "put-v3-projects-id-repository-branches-branch-unprotect" [
  id: string
  branch: string
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
    path: "/v3/projects/{id}/repository/branches/{branch}/unprotect"
    path_params: [{name: id, var: id}, {name: branch, var: branch}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project repository commits
#
# GET /v3/projects/{id}/repository/commits
# Returns: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>
# operationId: getV3ProjectsIdRepositoryCommits
export def "get-v3-projects-id-repository-commits" [
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
  --ref-name: string # The name of a repository branch or tag, if not given the default branch is used
  --since: string # Only commits after or in this date will be returned
  --until: string # Only commits before or in this date will be returned
  --page: int # The page for pagination (format: int32, default: 0)
  --per-page: int # The number of results per page (format: int32, default: 20)
  --path: string # The file path
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/commits"
    path_params: [{name: id, var: id}]
    query: [{name: ref_name, var: ref_name}, {name: since, var: since}, {name: until, var: until}, {name: page, var: page}, {name: per_page, var: per_page}, {name: path, var: path}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, ref_name: $ref_name, since: $since, until: $until, page: $page, per_page: $per_page, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Commit multiple file changes as one commit
#
# POST /v3/projects/{id}/repository/commits
# Returns: record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string>
# operationId: postV3ProjectsIdRepositoryCommits
export def "post-v3-projects-id-repository-commits" [
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
  branch_name: string # The name of branch
  commit_message: string # Commit message
  actions: list # Actions to perform in commit
  --author-email: string # Author email for commit
  --author-name: string # Author name for commit
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/commits"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: branch_name, var: branch_name}, {name: commit_message, var: commit_message}, {name: actions, var: actions, join: ","}, {name: author_email, var: author_email}, {name: author_name, var: author_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, branch_name: $branch_name, commit_message: $commit_message, actions: $actions, author_email: $author_email, author_name: $author_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}
# Returns: record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string>
# operationId: getV3ProjectsIdRepositoryCommitsSha
export def "get-v3-projects-id-repository-commits-sha" [
  id: string
  sha: string
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
    path: "/v3/projects/{id}/repository/commits/{sha}"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a raw file contents
#
# GET /v3/projects/{id}/repository/commits/{sha}/blob
# operationId: getV3ProjectsIdRepositoryCommitsShaBlob
export def "get-v3-projects-id-repository-commits-sha-blob" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filepath: string # The path to the file to display (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/commits/{sha}/blob"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    query: [{name: filepath, var: filepath, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, filepath: $filepath
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get builds for a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}/builds
# Returns: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>
# operationId: getV3ProjectsIdRepositoryCommitsShaBuilds
export def "get-v3-projects-id-repository-commits-sha-builds" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of builds to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/commits/{sha}/builds"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    query: [{name: scope, var: scope}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, scope: $scope, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cherry pick commit into a branch
#
# POST /v3/projects/{id}/repository/commits/{sha}/cherry_pick
# Returns: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>
# operationId: postV3ProjectsIdRepositoryCommitsShaCherryPick
export def "post-v3-projects-id-repository-commits-sha-cherry-pick" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  branch: string # The name of the branch
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/commits/{sha}/cherry_pick"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: branch, var: branch}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, sha: $sha, branch: $branch
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a commit's comments
#
# GET /v3/projects/{id}/repository/commits/{sha}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string>
# operationId: getV3ProjectsIdRepositoryCommitsShaComments
export def "get-v3-projects-id-repository-commits-sha-comments" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/commits/{sha}/comments"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post comment to commit
#
# POST /v3/projects/{id}/repository/commits/{sha}/comments
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string>
# operationId: postV3ProjectsIdRepositoryCommitsShaComments
export def "post-v3-projects-id-repository-commits-sha-comments" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
  --path: string # The file path
  line: int # The line number
  line_type: string@line-type-completer # The type of the line
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/commits/{sha}/comments"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: note, var: note}, {name: path, var: path}, {name: line, var: line}, {name: line_type, var: line_type}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, sha: $sha, note: $note, path: $path, line: $line, line_type: $line_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the diff for a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}/diff
# operationId: getV3ProjectsIdRepositoryCommitsShaDiff
export def "get-v3-projects-id-repository-commits-sha-diff" [
  id: string
  sha: string
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
    path: "/v3/projects/{id}/repository/commits/{sha}/diff"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a commit's statuses
#
# GET /v3/projects/{id}/repository/commits/{sha}/statuses
# Returns: record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string>
# operationId: getV3ProjectsIdRepositoryCommitsShaStatuses
export def "get-v3-projects-id-repository-commits-sha-statuses" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The ref
  --stage: string # The stage
  --name: string # The name
  --all: string # Show all statuses, default: false
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/commits/{sha}/statuses"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    query: [{name: ref, var: ref}, {name: stage, var: stage}, {name: name, var: name}, {name: all, var: all}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha, ref: $ref, stage: $stage, name: $name, all: $all, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Compare two branches, tags, or commits
#
# GET /v3/projects/{id}/repository/compare
# Returns: record<commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, compare_same_ref: string, compare_timeout: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>>
# operationId: getV3ProjectsIdRepositoryCompare
export def "get-v3-projects-id-repository-compare" [
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
  --from: string # The commit, branch name, or tag name to start comparison (required)
  --to: string # The commit, branch name, or tag name to stop comparison (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/compare"
    path_params: [{name: id, var: id}]
    query: [{name: from, var: from, required: true}, {name: to, var: to, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, from: $from, to: $to
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get repository contributors
#
# GET /v3/projects/{id}/repository/contributors
# Returns: record<additions: string, commits: string, deletions: string, email: string, name: string>
# operationId: getV3ProjectsIdRepositoryContributors
export def "get-v3-projects-id-repository-contributors" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/contributors"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing file in repository
#
# DELETE /v3/projects/{id}/repository/files
# operationId: deleteV3ProjectsIdRepositoryFiles
export def "delete-v3-projects-id-repository-files" [
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
  --file-path: string # The path to new file. Ex. lib/class.rb (required)
  --branch-name: string # The name of branch (required)
  --commit-message: string # Commit Message (required)
  --author-email: string # The email of the author
  --author-name: string # The name of the author
]: nothing -> any {
  http-request {
    method: delete
    path: "/v3/projects/{id}/repository/files"
    path_params: [{name: id, var: id}]
    query: [{name: file_path, var: file_path, required: true}, {name: branch_name, var: branch_name, required: true}, {name: commit_message, var: commit_message, required: true}, {name: author_email, var: author_email}, {name: author_name, var: author_name}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, file_path: $file_path, branch_name: $branch_name, commit_message: $commit_message, author_email: $author_email, author_name: $author_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a file from repository
#
# GET /v3/projects/{id}/repository/files
# operationId: getV3ProjectsIdRepositoryFiles
export def "get-v3-projects-id-repository-files" [
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
  --file-path: string # The path to the file. Ex. lib/class.rb (required)
  --ref: string # The name of branch, tag, or commit (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/files"
    path_params: [{name: id, var: id}]
    query: [{name: file_path, var: file_path, required: true}, {name: ref, var: ref, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, file_path: $file_path, ref: $ref
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new file in repository
#
# POST /v3/projects/{id}/repository/files
# operationId: postV3ProjectsIdRepositoryFiles
export def "post-v3-projects-id-repository-files" [
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
  file_path: string # The path to new file. Ex. lib/class.rb
  branch_name: string # The name of branch
  commit_message: string # Commit Message
  --author-email: string # The email of the author
  --author-name: string # The name of the author
  content: string # File content
  --encoding: string@encoding-completer # File encoding
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/files"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file_path, var: file_path}, {name: branch_name, var: branch_name}, {name: commit_message, var: commit_message}, {name: author_email, var: author_email}, {name: author_name, var: author_name}, {name: content, var: content}, {name: encoding, var: encoding}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, file_path: $file_path, branch_name: $branch_name, commit_message: $commit_message, author_email: $author_email, author_name: $author_name, content: $content, encoding: $encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update existing file in repository
#
# PUT /v3/projects/{id}/repository/files
# operationId: putV3ProjectsIdRepositoryFiles
export def "put-v3-projects-id-repository-files" [
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
  file_path: string # The path to new file. Ex. lib/class.rb
  branch_name: string # The name of branch
  commit_message: string # Commit Message
  --author-email: string # The email of the author
  --author-name: string # The name of the author
  content: string # File content
  --encoding: string@encoding-completer # File encoding
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/repository/files"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: file_path, var: file_path}, {name: branch_name, var: branch_name}, {name: commit_message, var: commit_message}, {name: author_email, var: author_email}, {name: author_name, var: author_name}, {name: content, var: content}, {name: encoding, var: encoding}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, file_path: $file_path, branch_name: $branch_name, commit_message: $commit_message, author_email: $author_email, author_name: $author_name, content: $content, encoding: $encoding
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v3/projects/{id}/repository/merged_branches
#
# operationId: deleteV3ProjectsIdRepositoryMergedBranches
export def "delete-v3-projects-id-repository-merged-branches" [
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
    path: "/v3/projects/{id}/repository/merged_branches"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a raw blob contents by blob sha
#
# GET /v3/projects/{id}/repository/raw_blobs/{sha}
# operationId: getV3ProjectsIdRepositoryRawBlobsSha
export def "get-v3-projects-id-repository-raw-blobs-sha" [
  id: string
  sha: string
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
    path: "/v3/projects/{id}/repository/raw_blobs/{sha}"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, sha: $sha
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project repository tags
#
# GET /v3/projects/{id}/repository/tags
# Returns: record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>
# operationId: getV3ProjectsIdRepositoryTags
export def "get-v3-projects-id-repository-tags" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/tags"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new repository tag
#
# POST /v3/projects/{id}/repository/tags
# Returns: record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>
# operationId: postV3ProjectsIdRepositoryTags
export def "post-v3-projects-id-repository-tags" [
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
  tag_name: string # The name of the tag
  ref: string # The commit sha or branch name
  --message: string # Specifying a message creates an annotated tag
  --release-description: string # Specifying release notes stored in the GitLab database
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/tags"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: tag_name, var: tag_name}, {name: ref, var: ref}, {name: message, var: message}, {name: release_description, var: release_description}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, tag_name: $tag_name, ref: $ref, message: $message, release_description: $release_description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a repository tag
#
# DELETE /v3/projects/{id}/repository/tags/{tag_name}
# operationId: deleteV3ProjectsIdRepositoryTagsTagName
export def "delete-v3-projects-id-repository-tags-tag-name" [
  id: string
  tag_name: string
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
    path: "/v3/projects/{id}/repository/tags/{tag_name}"
    path_params: [{name: id, var: id}, {name: tag_name, var: tag_name}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single repository tag
#
# GET /v3/projects/{id}/repository/tags/{tag_name}
# Returns: record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>>
# operationId: getV3ProjectsIdRepositoryTagsTagName
export def "get-v3-projects-id-repository-tags-tag-name" [
  id: string
  tag_name: string
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
    path: "/v3/projects/{id}/repository/tags/{tag_name}"
    path_params: [{name: id, var: id}, {name: tag_name, var: tag_name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, tag_name: $tag_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a release note to a tag
#
# POST /v3/projects/{id}/repository/tags/{tag_name}/release
# Returns: record<description: string, tag_name: string>
# operationId: postV3ProjectsIdRepositoryTagsTagNameRelease
export def "post-v3-projects-id-repository-tags-tag-name-release" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Release notes with markdown support
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/repository/tags/{tag_name}/release"
    path_params: [{name: id, var: id}, {name: tag_name, var: tag_name}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, tag_name: $tag_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a tag's release note
#
# PUT /v3/projects/{id}/repository/tags/{tag_name}/release
# Returns: record<description: string, tag_name: string>
# operationId: putV3ProjectsIdRepositoryTagsTagNameRelease
export def "put-v3-projects-id-repository-tags-tag-name-release" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Release notes with markdown support
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/repository/tags/{tag_name}/release"
    path_params: [{name: id, var: id}, {name: tag_name, var: tag_name}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, tag_name: $tag_name, description: $description
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a project repository tree
#
# GET /v3/projects/{id}/repository/tree
# Returns: record<id: string, mode: string, name: string, path: string, type: string>
# operationId: getV3ProjectsIdRepositoryTree
export def "get-v3-projects-id-repository-tree" [
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
  --ref-name: string # The name of a repository branch or tag, if not given the default branch is used
  --path: string # The path of the tree
  --recursive: oneof<nothing, bool> # Used to get a recursive tree
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/repository/tree"
    path_params: [{name: id, var: id}]
    query: [{name: ref_name, var: ref_name}, {name: path, var: path}, {name: recursive, var: recursive}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, ref_name: $ref_name, path: $path, recursive: $recursive
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get runners available for project
#
# GET /v3/projects/{id}/runners
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: getV3ProjectsIdRunners
export def "get-v3-projects-id-runners" [
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
  --scope: string@scope-completer-2 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/runners"
    path_params: [{name: id, var: id}]
    query: [{name: scope, var: scope}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, scope: $scope, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable a runner for a project
#
# POST /v3/projects/{id}/runners
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: postV3ProjectsIdRunners
export def "post-v3-projects-id-runners" [
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
  runner_id: int # The ID of the runner
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/runners"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: runner_id, var: runner_id}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, runner_id: $runner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Disable project's runner
#
# DELETE /v3/projects/{id}/runners/{runner_id}
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: deleteV3ProjectsIdRunnersRunnerId
export def "delete-v3-projects-id-runners-runner-id" [
  id: string
  runner_id: int
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
    method: delete
    path: "/v3/projects/{id}/runners/{runner_id}"
    path_params: [{name: id, var: id}, {name: runner_id, var: runner_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, runner_id: $runner_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set asana service for project
#
# PUT /v3/projects/{id}/services/asana
# operationId: putV3ProjectsIdServicesAsana
export def "put-v3-projects-id-services-asana" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # User API token
  --restrict-to-branch: string # Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/asana"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: api_key, var: api_key}, {name: restrict_to_branch, var: restrict_to_branch}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, api_key: $api_key, restrict_to_branch: $restrict_to_branch, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set assembla service for project
#
# PUT /v3/projects/{id}/services/assembla
# operationId: putV3ProjectsIdServicesAssembla
export def "put-v3-projects-id-services-assembla" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The authentication token (spec name: token)
  --subdomain: string # Subdomain setting
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/assembla"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: subdomain, var: subdomain}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, subdomain: $subdomain, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set bamboo service for project
#
# PUT /v3/projects/{id}/services/bamboo
# operationId: putV3ProjectsIdServicesBamboo
export def "put-v3-projects-id-services-bamboo" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bamboo_url: string # Bamboo root URL like https://bamboo.example.com
  build_key: string # Bamboo build plan key like
  username: string # A user with API access, if applicable
  password: string # Passord of the user
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/bamboo"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: bamboo_url, var: bamboo_url}, {name: build_key, var: build_key}, {name: username, var: username}, {name: password, var: password}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, bamboo_url: $bamboo_url, build_key: $build_key, username: $username, password: $password, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set bugzilla service for project
#
# PUT /v3/projects/{id}/services/bugzilla
# operationId: putV3ProjectsIdServicesBugzilla
export def "put-v3-projects-id-services-bugzilla" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # New issue URL
  issues_url: string # Issues URL
  project_url: string # Project URL
  --description: string # Description
  --title: string # Title
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/bugzilla"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: new_issue_url, var: new_issue_url}, {name: issues_url, var: issues_url}, {name: project_url, var: project_url}, {name: description, var: description}, {name: title, var: title}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, new_issue_url: $new_issue_url, issues_url: $issues_url, project_url: $project_url, description: $description, title: $title, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set buildkite service for project
#
# PUT /v3/projects/{id}/services/buildkite
# operationId: putV3ProjectsIdServicesBuildkite
export def "put-v3-projects-id-services-buildkite" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Buildkite project GitLab token (spec name: token)
  project_url: string # The buildkite project URL
  --enable-ssl-verification: oneof<nothing, bool> # Enable SSL verification for communication
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/buildkite"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: project_url, var: project_url}, {name: enable_ssl_verification, var: enable_ssl_verification}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, project_url: $project_url, enable_ssl_verification: $enable_ssl_verification, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set builds-email service for project
#
# PUT /v3/projects/{id}/services/builds-email
# operationId: putV3ProjectsIdServicesBuildsEmail
export def "put-v3-projects-id-services-builds-email" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --add-pusher: oneof<nothing, bool> # Add pusher to recipients list
  --notify-only-broken-builds: oneof<nothing, bool> # Notify only broken builds
  --build-events: string # Event will be triggered when a build status changes
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/builds-email"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: recipients, var: recipients}, {name: add_pusher, var: add_pusher}, {name: notify_only_broken_builds, var: notify_only_broken_builds}, {name: build_events, var: build_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, recipients: $recipients, add_pusher: $add_pusher, notify_only_broken_builds: $notify_only_broken_builds, build_events: $build_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set campfire service for project
#
# PUT /v3/projects/{id}/services/campfire
# operationId: putV3ProjectsIdServicesCampfire
export def "put-v3-projects-id-services-campfire" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Campfire token (spec name: token)
  --subdomain: string # Campfire subdomain
  --room: string # Campfire room
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/campfire"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: subdomain, var: subdomain}, {name: room, var: room}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, subdomain: $subdomain, room: $room, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set custom-issue-tracker service for project
#
# PUT /v3/projects/{id}/services/custom-issue-tracker
# operationId: putV3ProjectsIdServicesCustomIssueTracker
export def "put-v3-projects-id-services-custom-issue-tracker" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # New issue URL
  issues_url: string # Issues URL
  project_url: string # Project URL
  --description: string # Description
  --title: string # Title
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/custom-issue-tracker"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: new_issue_url, var: new_issue_url}, {name: issues_url, var: issues_url}, {name: project_url, var: project_url}, {name: description, var: description}, {name: title, var: title}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, new_issue_url: $new_issue_url, issues_url: $issues_url, project_url: $project_url, description: $description, title: $title, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set drone-ci service for project
#
# PUT /v3/projects/{id}/services/drone-ci
# operationId: putV3ProjectsIdServicesDroneCi
export def "put-v3-projects-id-services-drone-ci" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Drone CI token (spec name: token)
  drone_url: string # Drone CI URL
  --enable-ssl-verification: oneof<nothing, bool> # Enable SSL verification for communication
  --push-events: string # Event will be triggered by a push to the repository
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/drone-ci"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: drone_url, var: drone_url}, {name: enable_ssl_verification, var: enable_ssl_verification}, {name: push_events, var: push_events}, {name: merge_request_events, var: merge_request_events}, {name: tag_push_events, var: tag_push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, drone_url: $drone_url, enable_ssl_verification: $enable_ssl_verification, push_events: $push_events, merge_request_events: $merge_request_events, tag_push_events: $tag_push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set emails-on-push service for project
#
# PUT /v3/projects/{id}/services/emails-on-push
# operationId: putV3ProjectsIdServicesEmailsOnPush
export def "put-v3-projects-id-services-emails-on-push" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --disable-diffs: oneof<nothing, bool> # Disable code diffs
  --send-from-committer-email: oneof<nothing, bool> # Send from committer
  --push-events: string # Event will be triggered by a push to the repository
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/emails-on-push"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: recipients, var: recipients}, {name: disable_diffs, var: disable_diffs}, {name: send_from_committer_email, var: send_from_committer_email}, {name: push_events, var: push_events}, {name: tag_push_events, var: tag_push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, recipients: $recipients, disable_diffs: $disable_diffs, send_from_committer_email: $send_from_committer_email, push_events: $push_events, tag_push_events: $tag_push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set external-wiki service for project
#
# PUT /v3/projects/{id}/services/external-wiki
# operationId: putV3ProjectsIdServicesExternalWiki
export def "put-v3-projects-id-services-external-wiki" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  external_wiki_url: string # The URL of the external Wiki
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/external-wiki"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: external_wiki_url, var: external_wiki_url}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, external_wiki_url: $external_wiki_url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set flowdock service for project
#
# PUT /v3/projects/{id}/services/flowdock
# operationId: putV3ProjectsIdServicesFlowdock
export def "put-v3-projects-id-services-flowdock" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Flowdock token (spec name: token)
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/flowdock"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set gemnasium service for project
#
# PUT /v3/projects/{id}/services/gemnasium
# operationId: putV3ProjectsIdServicesGemnasium
export def "put-v3-projects-id-services-gemnasium" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # Your personal API key on gemnasium.com
  --body-token: string # The project's slug on gemnasium.com (spec name: token)
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/gemnasium"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: api_key, var: api_key}, {name: token, var: body_token, required: true}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, api_key: $api_key, body_token: $body_token, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set hipchat service for project
#
# PUT /v3/projects/{id}/services/hipchat
# operationId: putV3ProjectsIdServicesHipchat
export def "put-v3-projects-id-services-hipchat" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The room token (spec name: token)
  --room: string # The room name or ID
  --color: string # The room color
  --notify: oneof<nothing, bool> # Enable notifications
  --api-version: string # Leave blank for default (v2)
  --server: string # Leave blank for default. https://hipchat.example.com
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/hipchat"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: room, var: room}, {name: color, var: color}, {name: notify, var: notify}, {name: api_version, var: api_version}, {name: server, var: server}, {name: push_events, var: push_events}, {name: issue_events, var: issue_events}, {name: confidential_issue_events, var: confidential_issue_events}, {name: merge_request_events, var: merge_request_events}, {name: note_events, var: note_events}, {name: tag_push_events, var: tag_push_events}, {name: build_events, var: build_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, room: $room, color: $color, notify: $notify, api_version: $api_version, server: $server, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set irker service for project
#
# PUT /v3/projects/{id}/services/irker
# operationId: putV3ProjectsIdServicesIrker
export def "put-v3-projects-id-services-irker" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Recipients/channels separated by whitespaces
  --default-irc-uri: string # Default: irc://irc.network.net:6697
  --server-host: string # Server host. Default localhost
  --server-port: int # Server port. Default 6659
  --colorize-messages: oneof<nothing, bool> # Colorize messages
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/irker"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: recipients, var: recipients}, {name: default_irc_uri, var: default_irc_uri}, {name: server_host, var: server_host}, {name: server_port, var: server_port}, {name: colorize_messages, var: colorize_messages}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, recipients: $recipients, default_irc_uri: $default_irc_uri, server_host: $server_host, server_port: $server_port, colorize_messages: $colorize_messages, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set jira service for project
#
# PUT /v3/projects/{id}/services/jira
# operationId: putV3ProjectsIdServicesJira
export def "put-v3-projects-id-services-jira" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # The URL to the JIRA project which is being linked to this GitLab project, e.g., https://jira.example.com
  project_key: string # The short identifier for your JIRA project, all uppercase, e.g., PROJ
  --username: string # The username of the user created to be used with GitLab/JIRA
  --password: string # The password of the user created to be used with GitLab/JIRA
  --jira-issue-transition-id: int # The ID of a transition that moves issues to a closed state. You can find this number under the JIRA workflow administration (**Administration > Issues > Workflows**) by selecting **View** under **Operations** of the desired workflow of your project. The ID of each state can be found inside the parenthesis of each transition name under the **Transitions (id)** column ([see screenshot][trans]). By default, this ID is set to `2`
  --commit-events: string # Event will be triggered when a commit is created/updated
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/jira"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: url, var: url}, {name: project_key, var: project_key}, {name: username, var: username}, {name: password, var: password}, {name: jira_issue_transition_id, var: jira_issue_transition_id}, {name: commit_events, var: commit_events}, {name: merge_request_events, var: merge_request_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, url: $url, project_key: $project_key, username: $username, password: $password, jira_issue_transition_id: $jira_issue_transition_id, commit_events: $commit_events, merge_request_events: $merge_request_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set kubernetes service for project
#
# PUT /v3/projects/{id}/services/kubernetes
# operationId: putV3ProjectsIdServicesKubernetes
export def "put-v3-projects-id-services-kubernetes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  namespace: string # The Kubernetes namespace to use
  api_url: string # The URL to the Kubernetes cluster API, e.g., https://kubernetes.example.com
  --body-token: string # The service token to authenticate against the Kubernetes cluster with (spec name: token)
  --ca-pem: string # A custom certificate authority bundle to verify the Kubernetes cluster with (PEM format)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/kubernetes"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: namespace, var: namespace}, {name: api_url, var: api_url}, {name: token, var: body_token, required: true}, {name: ca_pem, var: ca_pem}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, namespace: $namespace, api_url: $api_url, body_token: $body_token, ca_pem: $ca_pem
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set mattermost service for project
#
# PUT /v3/projects/{id}/services/mattermost
# operationId: putV3ProjectsIdServicesMattermost
export def "put-v3-projects-id-services-mattermost" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook: string # The Mattermost webhook. e.g. http://mattermost_host/hooks/...
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
  --pipeline-events: string
  --wiki-page-events: string # Event will be triggered when a wiki page is created/updated
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/mattermost"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: webhook, var: webhook}, {name: push_events, var: push_events}, {name: issue_events, var: issue_events}, {name: confidential_issue_events, var: confidential_issue_events}, {name: merge_request_events, var: merge_request_events}, {name: note_events, var: note_events}, {name: tag_push_events, var: tag_push_events}, {name: build_events, var: build_events}, {name: pipeline_events, var: pipeline_events}, {name: wiki_page_events, var: wiki_page_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, webhook: $webhook, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set mattermost-slash-commands service for project
#
# PUT /v3/projects/{id}/services/mattermost-slash-commands
# operationId: putV3ProjectsIdServicesMattermostSlashCommands
export def "put-v3-projects-id-services-mattermost-slash-commands" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Mattermost token (spec name: token)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/mattermost-slash-commands"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a slash command for mattermost-slash-commands
#
# POST /v3/projects/{id}/services/mattermost_slash_commands/trigger
# operationId: postV3ProjectsIdServicesMattermostSlashCommandsTrigger
export def "post-v3-projects-id-services-mattermost-slash-commands-trigger" [
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
  --body-token: string # The Mattermost token (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/services/mattermost_slash_commands/trigger"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set pipelines-email service for project
#
# PUT /v3/projects/{id}/services/pipelines-email
# operationId: putV3ProjectsIdServicesPipelinesEmail
export def "put-v3-projects-id-services-pipelines-email" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --notify-only-broken-builds: oneof<nothing, bool> # Notify only broken builds
  --pipeline-events: string
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/pipelines-email"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: recipients, var: recipients}, {name: notify_only_broken_builds, var: notify_only_broken_builds}, {name: pipeline_events, var: pipeline_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, recipients: $recipients, notify_only_broken_builds: $notify_only_broken_builds, pipeline_events: $pipeline_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set pivotaltracker service for project
#
# PUT /v3/projects/{id}/services/pivotaltracker
# operationId: putV3ProjectsIdServicesPivotaltracker
export def "put-v3-projects-id-services-pivotaltracker" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Pivotaltracker token (spec name: token)
  --restrict-to-branch: string # Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches.
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/pivotaltracker"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}, {name: restrict_to_branch, var: restrict_to_branch}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token, restrict_to_branch: $restrict_to_branch, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set pushover service for project
#
# PUT /v3/projects/{id}/services/pushover
# operationId: putV3ProjectsIdServicesPushover
export def "put-v3-projects-id-services-pushover" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # The application key
  user_key: string # The user key
  priority: string # The priority
  device: string # Leave blank for all active devices
  sound: string # The sound of the notification
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/pushover"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: api_key, var: api_key}, {name: user_key, var: user_key}, {name: priority, var: priority}, {name: device, var: device}, {name: sound, var: sound}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, api_key: $api_key, user_key: $user_key, priority: $priority, device: $device, sound: $sound, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set redmine service for project
#
# PUT /v3/projects/{id}/services/redmine
# operationId: putV3ProjectsIdServicesRedmine
export def "put-v3-projects-id-services-redmine" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # The new issue URL
  project_url: string # The project URL
  issues_url: string # The issues URL
  --description: string # The description of the tracker
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/redmine"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: new_issue_url, var: new_issue_url}, {name: project_url, var: project_url}, {name: issues_url, var: issues_url}, {name: description, var: description}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, new_issue_url: $new_issue_url, project_url: $project_url, issues_url: $issues_url, description: $description, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set slack service for project
#
# PUT /v3/projects/{id}/services/slack
# operationId: putV3ProjectsIdServicesSlack
export def "put-v3-projects-id-services-slack" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook: string # The Slack webhook. e.g. https://hooks.slack.com/services/...
  --new-issue-url: string # The user name
  --channel: string # The channel name
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
  --pipeline-events: string
  --wiki-page-events: string # Event will be triggered when a wiki page is created/updated
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/slack"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: webhook, var: webhook}, {name: new_issue_url, var: new_issue_url}, {name: channel, var: channel}, {name: push_events, var: push_events}, {name: issue_events, var: issue_events}, {name: confidential_issue_events, var: confidential_issue_events}, {name: merge_request_events, var: merge_request_events}, {name: note_events, var: note_events}, {name: tag_push_events, var: tag_push_events}, {name: build_events, var: build_events}, {name: pipeline_events, var: pipeline_events}, {name: wiki_page_events, var: wiki_page_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, webhook: $webhook, new_issue_url: $new_issue_url, channel: $channel, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set slack-slash-commands service for project
#
# PUT /v3/projects/{id}/services/slack-slash-commands
# operationId: putV3ProjectsIdServicesSlackSlashCommands
export def "put-v3-projects-id-services-slack-slash-commands" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Slack token (spec name: token)
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/slack-slash-commands"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Trigger a slash command for slack-slash-commands
#
# POST /v3/projects/{id}/services/slack_slash_commands/trigger
# operationId: postV3ProjectsIdServicesSlackSlashCommandsTrigger
export def "post-v3-projects-id-services-slack-slash-commands-trigger" [
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
  --body-token: string # The Slack token (spec name: token)
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/services/slack_slash_commands/trigger"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: token, var: body_token, required: true}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, body_token: $body_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Set teamcity service for project
#
# PUT /v3/projects/{id}/services/teamcity
# operationId: putV3ProjectsIdServicesTeamcity
export def "put-v3-projects-id-services-teamcity" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  teamcity_url: string # TeamCity root URL like https://teamcity.example.com
  build_type: string # Build configuration ID
  username: string # A user with permissions to trigger a manual build
  password: string # The password of the user
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/services/teamcity"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: teamcity_url, var: teamcity_url}, {name: build_type, var: build_type}, {name: username, var: username}, {name: password, var: password}, {name: push_events, var: push_events}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, teamcity_url: $teamcity_url, build_type: $build_type, username: $username, password: $password, push_events: $push_events
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a service for project
#
# DELETE /v3/projects/{id}/services/{service_slug}
# operationId: deleteV3ProjectsIdServicesServiceSlug
export def "delete-v3-projects-id-services-service-slug" [
  id: int
  service_slug: string@service-slug-completer
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
    path: "/v3/projects/{id}/services/{service_slug}"
    path_params: [{name: id, var: id}, {name: service_slug, var: service_slug}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, service_slug: $service_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the service settings for project
#
# GET /v3/projects/{id}/services/{service_slug}
# Returns: record<active: string, build_events: string, created_at: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, properties: string, push_events: string, tag_push_events: string, title: string, updated_at: string>
# operationId: getV3ProjectsIdServicesServiceSlug
export def "get-v3-projects-id-services-service-slug" [
  id: int
  service_slug: string@service-slug-completer
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
    path: "/v3/projects/{id}/services/{service_slug}"
    path_params: [{name: id, var: id}, {name: service_slug, var: service_slug}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, service_slug: $service_slug
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Share the project with a group
#
# POST /v3/projects/{id}/share
# Returns: record<expires_at: string, group_access: string, group_id: string, id: string, project_id: string>
# operationId: postV3ProjectsIdShare
export def "post-v3-projects-id-share" [
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
  group_id: int # The ID of a group
  group_access: int@group-access-completer # The group access level
  --expires-at: string # Share expiration date
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/share"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: group_id, var: group_id}, {name: group_access, var: group_access}, {name: expires_at, var: expires_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, group_id: $group_id, group_access: $group_access, expires_at: $expires_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# DELETE /v3/projects/{id}/share/{group_id}
#
# operationId: deleteV3ProjectsIdShareGroupId
export def "delete-v3-projects-id-share-group-id" [
  id: string
  group_id: int
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
    path: "/v3/projects/{id}/share/{group_id}"
    path_params: [{name: id, var: id}, {name: group_id, var: group_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all project snippets
#
# GET /v3/projects/{id}/snippets
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>
# operationId: getV3ProjectsIdSnippets
export def "get-v3-projects-id-snippets" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/snippets"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new project snippet
#
# POST /v3/projects/{id}/snippets
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>
# operationId: postV3ProjectsIdSnippets
export def "post-v3-projects-id-snippets" [
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
  title: string # The title of the snippet
  file_name: string # The file name of the snippet
  code: string # The content of the snippet
  visibility_level: int@visibility-level-completer # The visibility level of the snippet
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/snippets"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: file_name, var: file_name}, {name: code, var: code}, {name: visibility_level, var: visibility_level}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, title: $title, file_name: $file_name, code: $code, visibility_level: $visibility_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/snippets/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdSnippetsNoteableIdNotes
export def "get-v3-projects-id-snippets-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/snippets/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/snippets/{noteable_id}/notes
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: postV3ProjectsIdSnippetsNoteableIdNotes
export def "post-v3-projects-id-snippets-noteable-id-notes" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/snippets/{noteable_id}/notes"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}, {name: created_at, var: created_at}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, body: $body, created_at: $created_at
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: deleteV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "delete-v3-projects-id-snippets-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    method: delete
    path: "/v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: getV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "get-v3-projects-id-snippets-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
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
    path: "/v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# Returns: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>
# operationId: putV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "put-v3-projects-id-snippets-noteable-id-notes-note-id" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string # The content of a note
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}"
    path_params: [{name: id, var: id}, {name: noteable_id, var: noteable_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, noteable_id: $noteable_id, note_id: $note_id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a project snippet
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}
# operationId: deleteV3ProjectsIdSnippetsSnippetId
export def "delete-v3-projects-id-snippets-snippet-id" [
  id: string
  snippet_id: int
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
    path: "/v3/projects/{id}/snippets/{snippet_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single project snippet
#
# GET /v3/projects/{id}/snippets/{snippet_id}
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>
# operationId: getV3ProjectsIdSnippetsSnippetId
export def "get-v3-projects-id-snippets-snippet-id" [
  id: string
  snippet_id: int
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
    path: "/v3/projects/{id}/snippets/{snippet_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing project snippet
#
# PUT /v3/projects/{id}/snippets/{snippet_id}
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string>
# operationId: putV3ProjectsIdSnippetsSnippetId
export def "put-v3-projects-id-snippets-snippet-id" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the snippet
  --file-name: string # The file name of the snippet
  --code: string # The content of the snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/snippets/{snippet_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: file_name, var: file_name}, {name: code, var: code}, {name: visibility_level, var: visibility_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, title: $title, file_name: $file_name, code: $code, visibility_level: $visibility_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdSnippetsSnippetIdAwardEmoji
export def "get-v3-projects-id-snippets-snippet-id-award-emoji" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/snippets/{snippet_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/snippets/{snippet_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdSnippetsSnippetIdAwardEmoji
export def "post-v3-projects-id-snippets-snippet-id-award-emoji" [
  id: int
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/snippets/{snippet_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdSnippetsSnippetIdAwardEmojiAwardId
export def "delete-v3-projects-id-snippets-snippet-id-award-emoji-award-id" [
  id: int
  snippet_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdSnippetsSnippetIdAwardEmojiAwardId
export def "get-v3-projects-id-snippets-snippet-id-award-emoji-award-id" [
  id: int
  snippet_id: int
  award_id: int
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
    path: "/v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji
export def "get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji" [
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: note_id, var: note_id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, note_id: $note_id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Award a new Emoji
#
# POST /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: postV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji
export def "post-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji" [
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: note_id, var: note_id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: name, var: name}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, note_id: $note_id, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: deleteV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId
export def "delete-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id" [
  id: int
  snippet_id: int
  note_id: int
  award_id: int
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
    method: delete
    path: "/v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}
# Returns: record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>>
# operationId: getV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId
export def "get-v3-projects-id-snippets-snippet-id-notes-note-id-award-emoji-award-id" [
  id: int
  snippet_id: int
  note_id: int
  award_id: int
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
    path: "/v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}, {name: note_id, var: note_id}, {name: award_id, var: award_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id, note_id: $note_id, award_id: $award_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a raw project snippet
#
# GET /v3/projects/{id}/snippets/{snippet_id}/raw
# operationId: getV3ProjectsIdSnippetsSnippetIdRaw
export def "get-v3-projects-id-snippets-snippet-id-raw" [
  id: string
  snippet_id: int
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
    path: "/v3/projects/{id}/snippets/{snippet_id}/raw"
    path_params: [{name: id, var: id}, {name: snippet_id, var: snippet_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, snippet_id: $snippet_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unstar a project
#
# DELETE /v3/projects/{id}/star
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: deleteV3ProjectsIdStar
export def "delete-v3-projects-id-star" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v3/projects/{id}/star"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Star a project
#
# POST /v3/projects/{id}/star
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3ProjectsIdStar
export def "post-v3-projects-id-star" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/projects/{id}/star"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Post status to a commit
#
# POST /v3/projects/{id}/statuses/{sha}
# Returns: record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string>
# operationId: postV3ProjectsIdStatusesSha
export def "post-v3-projects-id-statuses-sha" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string@state-completer-3 # The state of the status
  --ref: string # The ref
  --target-url: string # The target URL to associate with this status
  --description: string # A short description of the status
  --name: string # A string label to differentiate this status from the status of other systems. Default: "default"
  --context: string # A string label to differentiate this status from the status of other systems. Default: "default"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/statuses/{sha}"
    path_params: [{name: id, var: id}, {name: sha, var: sha}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: state, var: state}, {name: ref, var: ref}, {name: target_url, var: target_url}, {name: description, var: description}, {name: name, var: name}, {name: context, var: context}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, sha: $sha, state: $state, ref: $ref, target_url: $target_url, description: $description, name: $name, context: $context
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get triggers list
#
# GET /v3/projects/{id}/triggers
# Returns: record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>
# operationId: getV3ProjectsIdTriggers
export def "get-v3-projects-id-triggers" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/triggers"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a trigger
#
# POST /v3/projects/{id}/triggers
# Returns: record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>
# operationId: postV3ProjectsIdTriggers
export def "post-v3-projects-id-triggers" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/projects/{id}/triggers"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a trigger
#
# DELETE /v3/projects/{id}/triggers/{token}
# Returns: record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>
# operationId: deleteV3ProjectsIdTriggersToken
export def "delete-v3-projects-id-triggers-token" [
  id: string
  token_arg: string
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
    method: delete
    path: "/v3/projects/{id}/triggers/{token}"
    path_params: [{name: id, var: id}, {name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific trigger of a project
#
# GET /v3/projects/{id}/triggers/{token}
# Returns: record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string>
# operationId: getV3ProjectsIdTriggersToken
export def "get-v3-projects-id-triggers-token" [
  id: string
  token_arg: string
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
    path: "/v3/projects/{id}/triggers/{token}"
    path_params: [{name: id, var: id}, {name: token, var: token_arg}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, token_arg: $token_arg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unarchive a project
#
# POST /v3/projects/{id}/unarchive
# Returns: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>
# operationId: postV3ProjectsIdUnarchive
export def "post-v3-projects-id-unarchive" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/v3/projects/{id}/unarchive"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload a file
#
# POST /v3/projects/{id}/uploads
# operationId: postV3ProjectsIdUploads
export def "post-v3-projects-id-uploads" [
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
  file: path # The file to be uploaded
]: any -> any {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/uploads"
    path_params: [{name: id, var: id}]
    body: {content_type: "multipart/form-data", kind: multipart, fields: [{name: file, var: file}], files: [file]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, file: $file
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the users list of a project
#
# GET /v3/projects/{id}/users
# Returns: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3ProjectsIdUsers
export def "get-v3-projects-id-users" [
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
  --search: string # Return list of users matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/users"
    path_params: [{name: id, var: id}]
    query: [{name: search, var: search}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, search: $search, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get project variables
#
# GET /v3/projects/{id}/variables
# Returns: record<key: string, value: string>
# operationId: getV3ProjectsIdVariables
export def "get-v3-projects-id-variables" [
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
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/projects/{id}/variables"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new variable in a project
#
# POST /v3/projects/{id}/variables
# Returns: record<key: string, value: string>
# operationId: postV3ProjectsIdVariables
export def "post-v3-projects-id-variables" [
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
  key: string # The key of the variable
  value: string # The value of the variable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/projects/{id}/variables"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: key, var: key}, {name: value, var: value}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing variable from a project
#
# DELETE /v3/projects/{id}/variables/{key}
# Returns: record<key: string, value: string>
# operationId: deleteV3ProjectsIdVariablesKey
export def "delete-v3-projects-id-variables-key" [
  id: string
  key: string
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
    method: delete
    path: "/v3/projects/{id}/variables/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific variable from a project
#
# GET /v3/projects/{id}/variables/{key}
# Returns: record<key: string, value: string>
# operationId: getV3ProjectsIdVariablesKey
export def "get-v3-projects-id-variables-key" [
  id: string
  key: string
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
    path: "/v3/projects/{id}/variables/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key: $key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing variable from a project
#
# PUT /v3/projects/{id}/variables/{key}
# Returns: record<key: string, value: string>
# operationId: putV3ProjectsIdVariablesKey
export def "put-v3-projects-id-variables-key" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The value of the variable
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/projects/{id}/variables/{key}"
    path_params: [{name: id, var: id}, {name: key, var: key}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: value, var: value}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key: $key, value: $value
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get runners available for user
#
# GET /v3/runners
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: getV3Runners
export def "get-v3-runners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer-3 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runners"
    query: [{name: scope, var: scope}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    scope: $scope, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get all runners - shared and specific
#
# GET /v3/runners/all
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: getV3RunnersAll
export def "get-v3-runners-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer-2 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/runners/all"
    query: [{name: scope, var: scope}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    scope: $scope, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove a runner
#
# DELETE /v3/runners/{id}
# Returns: record<active: string, description: string, id: string, is_shared: string, name: string>
# operationId: deleteV3RunnersId
export def "delete-v3-runners-id" [
  id: int
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
    method: delete
    path: "/v3/runners/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get runner's details
#
# GET /v3/runners/{id}
# Returns: record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string>
# operationId: getV3RunnersId
export def "get-v3-runners-id" [
  id: int
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
    path: "/v3/runners/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update runner's details
#
# PUT /v3/runners/{id}
# Returns: record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string>
# operationId: putV3RunnersId
export def "put-v3-runners-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the runner
  --active: oneof<nothing, bool> # The state of a runner
  --tag-list: list<string> # The list of tags for a runner
  --run-untagged: oneof<nothing, bool> # Flag indicating the runner can execute untagged jobs
  --locked: oneof<nothing, bool> # Flag indicating the runner is locked
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/runners/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: description, var: description}, {name: active, var: active}, {name: tag_list, var: tag_list, join: ","}, {name: run_untagged, var: run_untagged}, {name: locked, var: locked}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, description: $description, active: $active, tag_list: $tag_list, run_untagged: $run_untagged, locked: $locked
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Login to get token
#
# POST /v3/session
# Returns: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, private_token: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>
# operationId: postV3Session
export def "post-v3-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # The username
  --email: string # The email of the user
  password: string # The password of the user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/session"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: login, var: login}, {name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    login: $login, email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Sidekiq Compound metrics. Includes queue, process, and job statistics
#
# GET /v3/sidekiq/compound_metrics
# operationId: getV3SidekiqCompoundMetrics
export def "get-v3-sidekiq-compound-metrics" [
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
    path: "/v3/sidekiq/compound_metrics"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Sidekiq job statistics
#
# GET /v3/sidekiq/job_stats
# operationId: getV3SidekiqJobStats
export def "get-v3-sidekiq-job-stats" [
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
    path: "/v3/sidekiq/job_stats"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Sidekiq process metrics
#
# GET /v3/sidekiq/process_metrics
# operationId: getV3SidekiqProcessMetrics
export def "get-v3-sidekiq-process-metrics" [
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
    path: "/v3/sidekiq/process_metrics"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the Sidekiq queue metrics
#
# GET /v3/sidekiq/queue_metrics
# operationId: getV3SidekiqQueueMetrics
export def "get-v3-sidekiq-queue-metrics" [
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
    path: "/v3/sidekiq/queue_metrics"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a snippets list for authenticated user
#
# GET /v3/snippets
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: getV3Snippets
export def "get-v3-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/snippets"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create new snippet
#
# POST /v3/snippets
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: postV3Snippets
export def "post-v3-snippets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of a snippet
  file_name: string # The name of a snippet file
  content: string # The content of a snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/snippets"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: file_name, var: file_name}, {name: content, var: content}, {name: visibility_level, var: visibility_level}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    title: $title, file_name: $file_name, content: $content, visibility_level: $visibility_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all public snippets current_user has access to
#
# GET /v3/snippets/public
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: getV3SnippetsPublic
export def "get-v3-snippets-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/snippets/public"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Remove snippet
#
# DELETE /v3/snippets/{id}
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: deleteV3SnippetsId
export def "delete-v3-snippets-id" [
  id: int
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
    method: delete
    path: "/v3/snippets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single snippet
#
# GET /v3/snippets/{id}
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: getV3SnippetsId
export def "get-v3-snippets-id" [
  id: int
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
    path: "/v3/snippets/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an existing snippet
#
# PUT /v3/snippets/{id}
# Returns: record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string>
# operationId: putV3SnippetsId
export def "put-v3-snippets-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of a snippet
  --file-name: string # The name of a snippet file
  --content: string # The content of a snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/snippets/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: title, var: title}, {name: file_name, var: file_name}, {name: content, var: content}, {name: visibility_level, var: visibility_level}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, title: $title, file_name: $file_name, content: $content, visibility_level: $visibility_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a raw snippet
#
# GET /v3/snippets/{id}/raw
# operationId: getV3SnippetsIdRaw
export def "get-v3-snippets-id-raw" [
  id: int
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
    path: "/v3/snippets/{id}/raw"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/templates/dockerfiles
# Returns: record<name: string>
# operationId: getV3TemplatesDockerfiles
export def "get-v3-templates-dockerfiles" [
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
    path: "/v3/templates/dockerfiles"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/dockerfiles/{name}
# Returns: record<content: string, name: string>
# operationId: getV3TemplatesDockerfilesName
export def "get-v3-templates-dockerfiles-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/templates/dockerfiles/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/templates/gitignores
# Returns: record<name: string>
# operationId: getV3TemplatesGitignores
export def "get-v3-templates-gitignores" [
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
    path: "/v3/templates/gitignores"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/gitignores/{name}
# Returns: record<content: string, name: string>
# operationId: getV3TemplatesGitignoresName
export def "get-v3-templates-gitignores-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/templates/gitignores/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available template
#
# GET /v3/templates/gitlab_ci_ymls
# Returns: record<name: string>
# operationId: getV3TemplatesGitlabCiYmls
export def "get-v3-templates-gitlab-ci-ymls" [
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
    path: "/v3/templates/gitlab_ci_ymls"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/gitlab_ci_ymls/{name}
# Returns: record<content: string, name: string>
# operationId: getV3TemplatesGitlabCiYmlsName
export def "get-v3-templates-gitlab-ci-ymls-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/templates/gitlab_ci_ymls/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of the available license template
#
# GET /v3/templates/licenses
# Returns: record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>
# operationId: getV3TemplatesLicenses
export def "get-v3-templates-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --popular: oneof<nothing, bool> # If passed, returns only popular licenses
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/templates/licenses"
    query: [{name: popular, var: popular}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    popular: $popular
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the text for a specific license
#
# GET /v3/templates/licenses/{name}
# Returns: record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string>
# operationId: getV3TemplatesLicensesName
export def "get-v3-templates-licenses-name" [
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
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/templates/licenses/{name}"
    path_params: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark all todos as done
#
# DELETE /v3/todos
# operationId: deleteV3Todos
export def "delete-v3-todos" [
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
    path: "/v3/todos"
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a todo list
#
# GET /v3/todos
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>
# operationId: getV3Todos
export def "get-v3-todos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/todos"
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Mark a todo as done
#
# DELETE /v3/todos/{id}
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string>
# operationId: deleteV3TodosId
export def "delete-v3-todos-id" [
  id: int
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
    method: delete
    path: "/v3/todos/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the currently authenticated user
#
# GET /v3/user
# Returns: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>
# operationId: getV3User
export def "get-v3-user" [
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
    path: "/v3/user"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the currently authenticated user's email addresses
#
# GET /v3/user/emails
# Returns: record<email: string, id: string>
# operationId: getV3UserEmails
export def "get-v3-user-emails" [
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
    path: "/v3/user/emails"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add new email address to the currently authenticated user
#
# POST /v3/user/emails
# Returns: record<email: string, id: string>
# operationId: postV3UserEmails
export def "post-v3-user-emails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The new email
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/user/emails"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an email address from the currently authenticated user
#
# DELETE /v3/user/emails/{email_id}
# operationId: deleteV3UserEmailsEmailId
export def "delete-v3-user-emails-email-id" [
  email_id: int
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
    path: "/v3/user/emails/{email_id}"
    path_params: [{name: email_id, var: email_id}]
    accept: ["application/json"]
    ok: [204]
    auth: private_header
  } {
    email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single email address owned by the currently authenticated user
#
# GET /v3/user/emails/{email_id}
# Returns: record<email: string, id: string>
# operationId: getV3UserEmailsEmailId
export def "get-v3-user-emails-email-id" [
  email_id: int
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
    path: "/v3/user/emails/{email_id}"
    path_params: [{name: email_id, var: email_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the currently authenticated user's SSH keys
#
# GET /v3/user/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3UserKeys
export def "get-v3-user-keys" [
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
    path: "/v3/user/keys"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a new SSH key to the currently authenticated user
#
# POST /v3/user/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3UserKeys
export def "post-v3-user-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new SSH key
  title: string # The title of the new SSH key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/user/keys"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: key, var: key}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    key: $key, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an SSH key from the currently authenticated user
#
# DELETE /v3/user/keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3UserKeysKeyId
export def "delete-v3-user-keys-key-id" [
  key_id: int
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
    method: delete
    path: "/v3/user/keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single key owned by currently authenticated user
#
# GET /v3/user/keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3UserKeysKeyId
export def "get-v3-user-keys-key-id" [
  key_id: int
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
    path: "/v3/user/keys/{key_id}"
    path_params: [{name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of users
#
# GET /v3/users
# Returns: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3Users
export def "get-v3-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Get a single user with a specific username
  --search: string # Search for a username
  --active: oneof<nothing, bool> # Filters only active users
  --external: oneof<nothing, bool> # Filters only external users
  --blocked: oneof<nothing, bool> # Filters only blocked users
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users"
    query: [{name: username, var: username}, {name: search, var: search}, {name: active, var: active}, {name: external, var: external}, {name: blocked, var: blocked}, {name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    username: $username, search: $search, active: $active, external: $external, blocked: $blocked, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a user. Available only for admins.
#
# POST /v3/users
# Returns: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>
# operationId: postV3Users
export def "post-v3-users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user
  password: string # The password of the new user
  name: string # The name of the user
  username: string # The username of the user
  --skype: string # The Skype username
  --linkedin: string # The LinkedIn username
  --twitter: string # The Twitter username
  --website-url: string # The website of the user
  --organization: string # The organization of the user
  --projects-limit: int # The number of projects a user can create
  --extern-uid: string # The external authentication provider UID
  --provider: string # The external provider
  --bio: string # The biography of the user
  --location: string # The location of the user
  --admin: oneof<nothing, bool> # Flag indicating the user is an administrator
  --can-create-group: oneof<nothing, bool> # Flag indicating the user can create groups
  --confirm: oneof<nothing, bool> # Flag indicating the account needs to be confirmed
  --external: oneof<nothing, bool> # Flag indicating the user is an external user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/users"
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}, {name: password, var: password}, {name: name, var: name}, {name: username, var: username}, {name: skype, var: skype}, {name: linkedin, var: linkedin}, {name: twitter, var: twitter}, {name: website_url, var: website_url}, {name: organization, var: organization}, {name: projects_limit, var: projects_limit}, {name: extern_uid, var: extern_uid}, {name: provider, var: provider}, {name: bio, var: bio}, {name: location, var: location}, {name: admin, var: admin}, {name: can_create_group, var: can_create_group}, {name: confirm, var: confirm}, {name: external, var: external}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    email: $email, password: $password, name: $name, username: $username, skype: $skype, linkedin: $linkedin, twitter: $twitter, website_url: $website_url, organization: $organization, projects_limit: $projects_limit, extern_uid: $extern_uid, provider: $provider, bio: $bio, location: $location, admin: $admin, can_create_group: $can_create_group, confirm: $confirm, external: $external
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a user. Available only for admins.
#
# DELETE /v3/users/{id}
# Returns: record<email: string, id: string>
# operationId: deleteV3UsersId
export def "delete-v3-users-id" [
  id: int
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
    method: delete
    path: "/v3/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a single user
#
# GET /v3/users/{id}
# Returns: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>
# operationId: getV3UsersId
export def "get-v3-users-id" [
  id: int
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
    path: "/v3/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a user. Available only for admins.
#
# PUT /v3/users/{id}
# Returns: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>
# operationId: putV3UsersId
export def "put-v3-users-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user
  --password: string # The password of the new user
  --name: string # The name of the user
  --username: string # The username of the user
  --skype: string # The Skype username
  --linkedin: string # The LinkedIn username
  --twitter: string # The Twitter username
  --website-url: string # The website of the user
  --organization: string # The organization of the user
  --projects-limit: int # The number of projects a user can create
  --extern-uid: string # The external authentication provider UID
  --provider: string # The external provider
  --bio: string # The biography of the user
  --location: string # The location of the user
  --admin: oneof<nothing, bool> # Flag indicating the user is an administrator
  --can-create-group: oneof<nothing, bool> # Flag indicating the user can create groups
  --confirm: oneof<nothing, bool> # Flag indicating the account needs to be confirmed
  --external: oneof<nothing, bool> # Flag indicating the user is an external user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v3/users/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}, {name: password, var: password}, {name: name, var: name}, {name: username, var: username}, {name: skype, var: skype}, {name: linkedin, var: linkedin}, {name: twitter, var: twitter}, {name: website_url, var: website_url}, {name: organization, var: organization}, {name: projects_limit, var: projects_limit}, {name: extern_uid, var: extern_uid}, {name: provider, var: provider}, {name: bio, var: bio}, {name: location, var: location}, {name: admin, var: admin}, {name: can_create_group, var: can_create_group}, {name: confirm, var: confirm}, {name: external, var: external}]}
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, email: $email, password: $password, name: $name, username: $username, skype: $skype, linkedin: $linkedin, twitter: $twitter, website_url: $website_url, organization: $organization, projects_limit: $projects_limit, extern_uid: $extern_uid, provider: $provider, bio: $bio, location: $location, admin: $admin, can_create_group: $can_create_group, confirm: $confirm, external: $external
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Block a user. Available only for admins.
#
# PUT /v3/users/{id}/block
# operationId: putV3UsersIdBlock
export def "put-v3-users-id-block" [
  id: int
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
    path: "/v3/users/{id}/block"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the emails addresses of a specified user. Available only for admins.
#
# GET /v3/users/{id}/emails
# Returns: record<email: string, id: string>
# operationId: getV3UsersIdEmails
export def "get-v3-users-id-emails" [
  id: int
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
    path: "/v3/users/{id}/emails"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an email address to a specified user. Available only for admins.
#
# POST /v3/users/{id}/emails
# Returns: record<email: string, id: string>
# operationId: postV3UsersIdEmails
export def "post-v3-users-id-emails" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/users/{id}/emails"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: email, var: email}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, email: $email
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an email address of a specified user. Available only for admins.
#
# DELETE /v3/users/{id}/emails/{email_id}
# Returns: record<email: string, id: string>
# operationId: deleteV3UsersIdEmailsEmailId
export def "delete-v3-users-id-emails-email-id" [
  id: int
  email_id: int
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
    method: delete
    path: "/v3/users/{id}/emails/{email_id}"
    path_params: [{name: id, var: id}, {name: email_id, var: email_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, email_id: $email_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the contribution events of a specified user
#
# GET /v3/users/{id}/events
# Returns: record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, "downvote?": string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, "upvote?": string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string>
# operationId: getV3UsersIdEvents
export def "get-v3-users-id-events" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3/users/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: page, var: page}, {name: per_page, var: per_page}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, page: $page, per_page: $per_page
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the SSH keys of a specified user. Available only for admins.
#
# GET /v3/users/{id}/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: getV3UsersIdKeys
export def "get-v3-users-id-keys" [
  id: int
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
    path: "/v3/users/{id}/keys"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add an SSH key to a specified user. Available only for admins.
#
# POST /v3/users/{id}/keys
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: postV3UsersIdKeys
export def "post-v3-users-id-keys" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new SSH key
  title: string # The title of the new SSH key
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3/users/{id}/keys"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/x-www-form-urlencoded", kind: form, fields: [{name: key, var: key}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [201]
    auth: private_header
  } {
    id: $id, key: $key, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing SSH key from a specified user. Available only for admins.
#
# DELETE /v3/users/{id}/keys/{key_id}
# Returns: record<can_push: string, created_at: string, id: string, key: string, title: string>
# operationId: deleteV3UsersIdKeysKeyId
export def "delete-v3-users-id-keys-key-id" [
  id: int
  key_id: int
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
    method: delete
    path: "/v3/users/{id}/keys/{key_id}"
    path_params: [{name: id, var: id}, {name: key_id, var: key_id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id, key_id: $key_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unblock a user. Available only for admins.
#
# PUT /v3/users/{id}/unblock
# operationId: putV3UsersIdUnblock
export def "put-v3-users-id-unblock" [
  id: int
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
    path: "/v3/users/{id}/unblock"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the version information of the GitLab instance.
#
# GET /v3/version
# operationId: getV3Version
export def "get-v3-version" [
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
    path: "/v3/version"
    accept: ["application/json"]
    ok: [200]
    auth: private_header
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
