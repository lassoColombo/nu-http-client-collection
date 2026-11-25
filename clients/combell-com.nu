# Auto-generated client for Public Api v2
# Source: https://api.apis.guru/v2/specs/combell.com/v2/openapi.json
# Auth: --token flag or $env.PUBLIC_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/v2"
  token_env_var: "PUBLIC_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def asset-type-completer [] { ["dns" "domain" "linux_hosting" "mailbox" "mysql" "windows_hosting"] }
def type-completer [] { ["advanced" "basic" "none"] }
def certificate-type-completer [] { ["multi_domain" "standard" "wildcard"] }
def validation-level-completer [] { ["domain_validated" "extended_validated" "organization_validated"] }
def file-format-completer [] { ["pfx"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-accounts: "table<id: int, identifier: string, servicepack_id: int>"
    get-account: "record<addons: table<id: int, name: string>, id: int, identifier: string, servicepack: record<id: int, name: string>>"
    get-dns-domain-name-records: "table<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int>"
    get-dns-domain-name-records-record-id: "record<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int>"
    get-domains: "table<domain_name: string, expiration_date: string, will_renew: bool>"
    get-domain: "record<can_toggle_renew: bool, domain_name: string, expiration_date: string, name_servers: table<ip: string, name: string>, registrant: record<address: string, city: string, company_name: string, country_code: string, email: string, enterprise_number: string, fax: string, first_name: string, language_code: string, last_name: string, phone: string, postal_code: string>, will_renew: bool>"
    get-linux-hostings: "table<domain_name: string, servicepack_id: int>"
    get-linux-hosting: "record<actual_size: int, domain_name: string, ftp_enabled: bool, ftp_username: string, ip: string, ip_type: string, max_size: int, max_webspace_size: int, mysql_database_names: list<string>, php_version: string, servicepack_id: int, sites: table<host_headers: list, http2_enabled: bool, https_redirect_enabled: bool, name: string, path: string, ssl_enabled: bool>, ssh_host: string, ssh_username: string, webspace_usage: int>"
    get-available-php-versions: "table<version: string>"
    get-scheduled-tasks: "table<cron_expression: string, enabled: bool, id: string, script_location: string>"
    get-scheduled-task: "record<cron_expression: string, enabled: bool, id: string, script_location: string>"
    get-ssh-keys: "table<fingerprint: string, public_key: string>"
    get-mailboxes: "table<actual_size: int, max_size: int, name: string>"
    get-mailbox: "record<actual_size: int, auto_forward: record<copy_to_myself: bool, email_addresses: list<string>, enabled: bool>, auto_reply: record<enabled: bool, message: string, subject: string>, login: string, max_size: int, name: string>"
    get-mail-zone: "record<aliases: table<destinations: list, email_address: string>, anti_spam: record<allowed_types: list<string>, type: string>, available_accounts: table<account_id: int, size: int>, catch_all: record<email_addresses: list<string>>, enabled: bool, name: string, smtp_domains: table<enabled: bool, hostname: string>>"
    get-my-sql-databases: "table<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int>"
    get-my-sql-database: "record<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int>"
    get-database-users: "table<enabled: bool, name: string, rights: string>"
    get-provisioningjobs-job-id: "record<completion: record<estimate: string>, id: string, status: string>"
    servicepacks: "table<id: int, name: string>"
    get-all-ssh-keys: "table<fingerprint: string, linux_hostings: list<string>, public_key: string>"
    get-ssl-certificate-requests: "table<certificate_type: string, common_name: string, id: int, order_code: string, validation_level: string, vendor: string>"
    get-ssl-certificate-request: "record<certificate_type: string, common_name: string, id: int, order_code: string, subject_alt_names: table<type: string, value: string>, validation_level: string, validations: table<auto_validated: bool, cname_validation_content: string, cname_validation_name: string, dns_name: string, email_addresses: list, file_validation_content: list, file_validation_url_http: string, file_validation_url_https: string, type: string>, vendor: string>"
    get-ssl-certificates: "table<common_name: string, expires_after: string, sha1_fingerprint: string, type: string, validation_level: string>"
    get-ssl-certificate: "record<common_name: string, expires_after: string, sha1_fingerprint: string, subject_alt_names: table<type: string, value: string>, type: string, validation_level: string>"
    download-certificate: "binary"
    get-windows-hostings: "table<domain_name: string, servicepack_id: int>"
    get-windows-hosting: "record<actual_size: int, application_pool: record<installed_net_core_runtimes: list<string>, pipeline_mode: string, runtime: string>, domain_name: string, ftp_username: string, ip: string, ip_type: string, max_size: int, mssql_database_names: list<string>, servicepack_id: int, sites: table<bindings: list, name: string, path: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-accounts" "create-account" "get-account" "get-dns-domain-name-records" "post-dns-domain-name-records" "delete-dns-domain-name-records-record-id" "get-dns-domain-name-records-record-id" "put-dns-domain-name-records-record-id" "get-domains" "register" "transfer" "get-domain" "edit-name-servers" "configure-domain" "get-linux-hostings" "get-linux-hosting" "configure-ftp" "change-apcu" "get-available-php-versions" "change-php-memory-limit" "change-php-version" "get-scheduled-tasks" "add-scheduled-tasks" "delete-scheduled-task" "get-scheduled-task" "configure-scheduled-task" "change-gzip-compression" "create-host-header" "configure-http2" "configure-ssh" "get-ssh-keys" "add-ssh-key" "delete-ssh-key" "change-auto-redirect" "change-lets-encrypt" "create-subsite" "delete-subsite" "get-mailboxes" "create-mailbox" "delete-mailbox" "get-mailbox" "configure-mailbox-auto-forward" "configure-mailbox-auto-reply" "change-mailbox-password" "get-mail-zone" "create-alias" "delete-alias" "configure-alias" "configure-anti-spam" "create-catch-all" "delete-catch-all" "create-smtp-domain" "delete-smtp-domain" "configure-smtp-domain" "get-my-sql-databases" "create-my-sql-database" "delete-database" "get-my-sql-database" "get-database-users" "create-my-sql-user" "delete-database-user" "change-database-user-password" "change-database-user-status" "get-provisioningjobs-job-id" "servicepacks" "get-all-ssh-keys" "get-ssl-certificate-requests" "add-ssl-certificate-request" "get-ssl-certificate-request" "verify-ssl-certificate-request-domain-validations" "get-ssl-certificates" "get-ssl-certificate" "download-certificate" "get-windows-hostings" "get-windows-hosting" "commands"] | sort) } | get name | first)
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

# Overview of accounts
#
# GET /accounts
# Returns: table<id: int, identifier: string, servicepack_id: int>
# operationId: GetAccounts
export def "get-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
  --asset-type: string@asset-type-completer # Filters the list, returning only accounts containing the specified asset type.
  --identifier: string # Return only accounts, matching the specified identifier. (nullable)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/accounts"
    query: [{name: skip, var: skip}, {name: take, var: take}, {name: asset_type, var: asset_type}, {name: identifier, var: identifier}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take, asset_type: $asset_type, identifier: $identifier
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new account
#
# POST /accounts
# operationId: CreateAccount
export def "create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ftp-password: string # Ftp password for the account. Applies only if the servicepack contains hosting. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
  --identifier: string # An identifier for the account. Should be a domain name for hosting accounts.
  --servicepack-id: int # The servicepack id that defines the account. (format: int32)
]: any -> any {
  $in | http-request {
    method: post
    path: "/accounts"
    body: {content_type: "application/json", kind: json, fields: [{name: ftp_password, var: ftp_password}, {name: identifier, var: identifier}, {name: servicepack_id, var: servicepack_id}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    ftp_password: $ftp_password, identifier: $identifier, servicepack_id: $servicepack_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific account
#
# GET /accounts/{accountId}
# Returns: record<addons: table<id: int, name: string>, id: int, identifier: string, servicepack: record<id: int, name: string>>
# operationId: GetAccount
export def "get-account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-account-id: int # The id of the account. (required, format: int32) (spec name: account_id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/accounts/{accountId}"
    path_params: [{name: accountId, var: account_id}]
    query: [{name: account_id, var: qp_account_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    account_id: $account_id, qp_account_id: $qp_account_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get records
#
# GET /dns/{domainName}/records
# Returns: table<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int>
export def "get-dns-domain-name-records" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name. (required) (spec name: domain_name)
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
  --type: string # Filters records matching the type. Most other filters only apply when this filter is specified. (nullable)
  --record-name: string # Filters records matching the record name. This filter only applies to lookups of A, CNAME, TXT, CAA, ALIAS and TLSA records. (nullable)
  --service: string # Filters records for the service. This filter only applies to lookups of SRV records. (nullable)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/dns/{domainName}/records"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: skip, var: skip}, {name: take, var: take}, {name: type, var: type}, {name: record_name, var: record_name}, {name: service, var: service}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, skip: $skip, take: $take, type: $type, record_name: $record_name, service: $service
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a record
#
# POST /dns/{domainName}/records
export def "post-dns-domain-name-records" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name. (required) (spec name: domain_name)
  --content: string # Variable data depending on the record type. A: the IPv4 address.CNAME: canonical name of an alias.MX: fully qualified domain name of a mail host.SRV: does not apply. Data for the SRV records can be found in specific properties.TXT: free form text data.CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}". The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.The value "iodef": specifies a URL to which a certificate authority may report policy violations.The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.ALIAS: canonical name of an alias.TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}" The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.A value of 0 means to select the entire certificate for matching.A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.The matching type.A type of 0 means the entire information selected is present in the certificate association data.A type of 1 means to do a SHA-256 hash of the selected data.A type of 2 means to do a SHA-512 hash of the selected data.The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records. The value MUST be a positive integer. Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records. A lower value means more preferred. The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ... Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record. This is the host name, alias defined by the record. An empty record or '@' is equal to the domain name. Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records. When type is TLSA the recommended value format is port number, protocol and host: _25._tcp. Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records. Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records. Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds. It defines the time frame that clients can cache the information. The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority. A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  $in | http-request {
    method: post
    path: "/dns/{domainName}/records"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: id, var: id}, {name: port, var: port}, {name: priority, var: priority}, {name: protocol, var: protocol}, {name: record_name, var: record_name}, {name: service, var: service}, {name: target, var: target}, {name: ttl, var: ttl}, {name: type, var: type}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, content: $content, id: $id, port: $port, priority: $priority, protocol: $protocol, record_name: $record_name, service: $service, target: $target, ttl: $ttl, type: $type, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a record
#
# DELETE /dns/{domainName}/records/{recordId}
export def "delete-dns-domain-name-records-record-id" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name. (required) (spec name: domain_name)
  --qp-record-id: string # The id of the record. (required) (spec name: record_id)
]: nothing -> any {
  http-request {
    method: delete
    path: "/dns/{domainName}/records/{recordId}"
    path_params: [{name: domainName, var: domain_name}, {name: recordId, var: record_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: record_id, var: qp_record_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, record_id: $record_id, qp_domain_name: $qp_domain_name, qp_record_id: $qp_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get specific record
#
# GET /dns/{domainName}/records/{recordId}
# Returns: record<content: string, id: string, port: int, priority: int, protocol: string, record_name: string, service: string, target: string, ttl: int, type: string, weight: int>
export def "get-dns-domain-name-records-record-id" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name. (required) (spec name: domain_name)
  --qp-record-id: string # The id of the record. (required) (spec name: record_id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/dns/{domainName}/records/{recordId}"
    path_params: [{name: domainName, var: domain_name}, {name: recordId, var: record_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: record_id, var: qp_record_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, record_id: $record_id, qp_domain_name: $qp_domain_name, qp_record_id: $qp_record_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit a record
#
# PUT /dns/{domainName}/records/{recordId}
export def "put-dns-domain-name-records-record-id" [
  domain_name: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name. (required) (spec name: domain_name)
  --qp-record-id: string # The id of the record. (required) (spec name: record_id)
  --content: string # Variable data depending on the record type. A: the IPv4 address.CNAME: canonical name of an alias.MX: fully qualified domain name of a mail host.SRV: does not apply. Data for the SRV records can be found in specific properties.TXT: free form text data.CAA: format should match specific values for flag, tag and ca: "{flag} {tag} {ca}". The flag. The values 128 (critical) or 0 (non-critical) are expected, with 0 as the default.The tag. A tag specifies which actions an authorized CA can take in terms of issuing SSL/TLS certificates.The value "issue": explicitly authorizes a single certificate authority to issue a certificate (any type) for the hostname.The value "issuewild": explicitly authorizes a single certificate authority to issue a wildcard certificate (and only wildcard) for the hostname.The value "iodef": specifies a URL to which a certificate authority may report policy violations.The ca. This is the domain of the CA (Certification Authority) that has the authority to issue certificates for the domain in question. If the value is a semicolon (;), it means that no CA has the authority to issue a certificate for that domain.ALIAS: canonical name of an alias.TLSA: format should match specific values for usage, selector, matching type and data: "{usage} {selector} {matching_type} {data}" The usage. The first field after the TLSA text in the DNS RR, specifies how to verify the certificate.A value of 0 is for what is commonly called CA constraint (and PKIX-TA). The certificate provided when establishing TLS must be issued by the listed root-CA or one of its intermediate CAs, with a valid certification path to a root-CA already trusted by the application doing the verification.A value of 1 is for what is commonly called Service certificate constraint (and PKIX-EE). The certificate used must match the TLSA record exactly, and it must also pass PKIX certification path validation to a trusted root-CA.A value of 2 is for what is commonly called Trust Anchor Assertion (and DANE-TA). The certificate used has a valid certification path pointing back to the certificate mention in this record, but there is no need for it to pass the PKIX certification path validation to a trusted root-CA.A value of 3 is for what is commonly called Domain issued certificate (and DANE-EE). The services uses a self-signed certificate. It is not signed by anyone else, and is exactly this record.The selector. When connecting to the service and a certificate is received, the selector field specifies which parts of it should be checked.A value of 0 means to select the entire certificate for matching.A value of 1 means to select just the public key for certificate matching. Matching the public key is often sufficient, as this is likely to be unique.The matching type.A type of 0 means the entire information selected is present in the certificate association data.A type of 1 means to do a SHA-256 hash of the selected data.A type of 2 means to do a SHA-512 hash of the selected data.The actual data to be matched given the settings of the other fields. This is a long text string of hexadecimal data.
  --id: string # The id of the record This value is ignored for creation of new records.
  --port: int # The port for SRV records. The value MUST be a positive integer. Editing the value is not possible. You should add a new SRV record and delete the existing record. (format: int32)
  --priority: int # The priority for MX or SRV records. A lower value means more preferred. The value MUST be a positive integer less or equal to 9999. (format: int32, default: 10)
  --protocol: string # Used for the creation of SRV records. Possible options: TCP, UDP, ... Editing the value is not possible. You should add a new SRV record and delete the existing record. (default: TCP)
  --record-name: string # The name of the record. This is the host name, alias defined by the record. An empty record or '@' is equal to the domain name. Applies to A, MX, CNAME, TXT, CAA, ALIAS and TLSA records. When type is TLSA the recommended value format is port number, protocol and host: _25._tcp. Does not apply for SRV records.
  --service: string # The symbolic name of the desired service for SRV records. Editing the value is not possible. You should add a new SRV record and can delete the existing record.
  --target: string # The canonical hostname of the machine providing the service for SRV records. Editing the value is not possible. You should add a new SRV record and delete the existing record.
  --ttl: int # Time to live of the record in seconds. It defines the time frame that clients can cache the information. The value MUST be between 60 and 86400. The default value is 3600 (= 1 hour). (format: int32, default: 3600)
  --type: string # The type of the record (A, MX, CNAME, SRV, TXT, CAA, ALIAS and TLSA).
  --weight: int # The weight for SRV records with the same priority. A higher value means more preferred. (format: int32, default: 0)
]: any -> any {
  $in | http-request {
    method: put
    path: "/dns/{domainName}/records/{recordId}"
    path_params: [{name: domainName, var: domain_name}, {name: recordId, var: record_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: record_id, var: qp_record_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: content, var: content}, {name: id, var: id}, {name: port, var: port}, {name: priority, var: priority}, {name: protocol, var: protocol}, {name: record_name, var: record_name}, {name: service, var: service}, {name: target, var: target}, {name: ttl, var: ttl}, {name: type, var: type}, {name: weight, var: weight}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, record_id: $record_id, qp_domain_name: $qp_domain_name, qp_record_id: $qp_record_id, content: $content, id: $id, port: $port, priority: $priority, protocol: $protocol, record_name: $record_name, service: $service, target: $target, ttl: $ttl, type: $type, weight: $weight
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overviews of domains
#
# GET /domains
# Returns: table<domain_name: string, expiration_date: string, will_renew: bool>
# operationId: GetDomains
export def "get-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/domains"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Register a domain
#
# POST /domains/registrations
# operationId: Register
export def "register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name to register. Only pass the domain part and the tld.For abc.com, abc is the domain part, com is the tld.
  --name-servers: list<string> # List of name servers. When empty, the registation will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/registrations"
    body: {content_type: "application/json", kind: json, fields: [{name: domain_name, var: domain_name}, {name: name_servers, var: name_servers}, {name: registrant, var: registrant}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    domain_name: $domain_name, name_servers: $name_servers, registrant: $registrant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Transfer a domain
#
# POST /domains/transfers
# operationId: Transfer
export def "transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-code: string # Authorization code which allows the transfer to execute.
  --domain-name: string # The domain name to transfer. Only pass the domain part and the tld.For abc.com, abc is the domain part, com is the tld.
  --name-servers: list<string> # List of name servers. When empty, the transfer will be done on default name servers.
  --registrant: record # shape: {address?: string, city?: string, company_name?: string, country_code?: string, email?: string, enterprise_number?: string, extra_fields?: list, fax?: string, first_name?: string, language_code?: string, last_name?: string, phone?: string, postal_code?: string}
]: any -> any {
  $in | http-request {
    method: post
    path: "/domains/transfers"
    body: {content_type: "application/json", kind: json, fields: [{name: auth_code, var: auth_code}, {name: domain_name, var: domain_name}, {name: name_servers, var: name_servers}, {name: registrant, var: registrant}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    auth_code: $auth_code, domain_name: $domain_name, name_servers: $name_servers, registrant: $registrant
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Details of a domain
#
# GET /domains/{domainName}
# Returns: record<can_toggle_renew: bool, domain_name: string, expiration_date: string, name_servers: table<ip: string, name: string>, registrant: record<address: string, city: string, company_name: string, country_code: string, email: string, enterprise_number: string, fax: string, first_name: string, language_code: string, last_name: string, phone: string, postal_code: string>, will_renew: bool>
# operationId: GetDomain
export def "get-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name (required) (spec name: domain_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/domains/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit domain name servers
#
# PUT /domains/{domainName}/nameservers
# operationId: EditNameServers
export def "edit-name-servers" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name (required) (spec name: domain_name)
  --body-domain-name: string # The domain name to register. (spec name: domain_name)
  --name-servers: list<string> # List of name servers.
]: any -> any {
  $in | http-request {
    method: put
    path: "/domains/{domainName}/nameservers"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain_name, var: body_domain_name}, {name: name_servers, var: name_servers}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, body_domain_name: $body_domain_name, name_servers: $name_servers
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Edit domain name renew state
#
# PUT /domains/{domainName}/renew
# operationId: ConfigureDomain
export def "configure-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The domain name (required) (spec name: domain_name)
  --will-renew: oneof<nothing, bool> # Indication of renewal.
]: any -> any {
  $in | http-request {
    method: put
    path: "/domains/{domainName}/renew"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: will_renew, var: will_renew}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, will_renew: $will_renew
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of linux hostings
#
# GET /linuxhostings
# Returns: table<domain_name: string, servicepack_id: int>
# operationId: GetLinuxHostings
export def "get-linux-hostings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Linux hosting detail
#
# GET /linuxhostings/{domainName}
# Returns: record<actual_size: int, domain_name: string, ftp_enabled: bool, ftp_username: string, ip: string, ip_type: string, max_size: int, max_webspace_size: int, mysql_database_names: list<string>, php_version: string, servicepack_id: int, sites: table<host_headers: list, http2_enabled: bool, https_redirect_enabled: bool, name: string, path: string, ssl_enabled: bool>, ssh_host: string, ssh_username: string, webspace_usage: int>
# operationId: GetLinuxHosting
export def "get-linux-hosting" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The Linux hosting domain name. (required) (spec name: domain_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure FTP
#
# PUT /linuxhostings/{domainName}/ftp/configuration
# operationId: ConfigureFtp
export def "configure-ftp" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enable or disable FTP.
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/ftp/configuration"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure PHP APCu setting
#
# PUT /linuxhostings/{domainName}/phpsettings/apcu
# operationId: ChangeApcu
export def "change-apcu" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name (required) (spec name: domain_name)
  --apcu-size: int # The APcu size. (format: int32)
  --enabled: oneof<nothing, bool> # Enables or disables APC.
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/phpsettings/apcu"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: apcu_size, var: apcu_size}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, apcu_size: $apcu_size, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the available PHP versions.
#
# GET /linuxhostings/{domainName}/phpsettings/availableversions
# Returns: table<version: string>
# operationId: GetAvailablePhpVersions
export def "get-available-php-versions" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings/{domainName}/phpsettings/availableversions"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure PHP memory limit
#
# PUT /linuxhostings/{domainName}/phpsettings/memorylimit
# operationId: ChangePhpMemoryLimit
export def "change-php-memory-limit" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --memory-limit: int # The php memory limit (format: int32)
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/phpsettings/memorylimit"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: memory_limit, var: memory_limit}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, memory_limit: $memory_limit
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change the Linux hosting PHP version.
#
# PUT /linuxhostings/{domainName}/phpsettings/version
# operationId: ChangePhpVersion
export def "change-php-version" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --version: string # Php version
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/phpsettings/version"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: version, var: version}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of scheduled tasks
#
# GET /linuxhostings/{domainName}/scheduledtasks
# Returns: table<cron_expression: string, enabled: bool, id: string, script_location: string>
# operationId: GetScheduledTasks
export def "get-scheduled-tasks" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings/{domainName}/scheduledtasks"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a scheduled task
#
# POST /linuxhostings/{domainName}/scheduledtasks
# operationId: AddScheduledTasks
export def "add-scheduled-tasks" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --cron-expression: string # Cron expression of scheduled task. 5-digit expressions (*/5 * * * *) are required in the following sequence:Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)Hour (0 - 23, also * as every hour is allowed)Day of the month (1 - 31, also * as every day is allowed)Month (1 - 12 as January to December, also * as every month is allowed)Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task. This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  $in | http-request {
    method: post
    path: "/linuxhostings/{domainName}/scheduledtasks"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: cron_expression, var: cron_expression}, {name: enabled, var: enabled}, {name: id, var: id}, {name: script_location, var: script_location}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, cron_expression: $cron_expression, enabled: $enabled, id: $id, script_location: $script_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a scheduled task
#
# DELETE /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: DeleteScheduledTask
export def "delete-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-scheduled-task-id: string # Id of the scheduled task. (required) (spec name: scheduled_task_id)
]: nothing -> any {
  http-request {
    method: delete
    path: "/linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}"
    path_params: [{name: domainName, var: domain_name}, {name: scheduledTaskId, var: scheduled_task_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: scheduled_task_id, var: qp_scheduled_task_id, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, scheduled_task_id: $scheduled_task_id, qp_domain_name: $qp_domain_name, qp_scheduled_task_id: $qp_scheduled_task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get scheduled task detail
#
# GET /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# Returns: record<cron_expression: string, enabled: bool, id: string, script_location: string>
# operationId: GetScheduledTask
export def "get-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-scheduled-task-id: string # Id of the scheduled task. (required) (spec name: scheduled_task_id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}"
    path_params: [{name: domainName, var: domain_name}, {name: scheduledTaskId, var: scheduled_task_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: scheduled_task_id, var: qp_scheduled_task_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, scheduled_task_id: $scheduled_task_id, qp_domain_name: $qp_domain_name, qp_scheduled_task_id: $qp_scheduled_task_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure a scheduled task
#
# PUT /linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}
# operationId: ConfigureScheduledTask
export def "configure-scheduled-task" [
  domain_name: string
  scheduled_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-scheduled-task-id: string # Id of the scheduled task. (required) (spec name: scheduled_task_id)
  --cron-expression: string # Cron expression of scheduled task. 5-digit expressions (*/5 * * * *) are required in the following sequence:Minute (0 - 59, also */5, */10, */15 and */30 as every 5 minutes, every 10 minutes, every quarter or every half-hour are allowed)Hour (0 - 23, also * as every hour is allowed)Day of the month (1 - 31, also * as every day is allowed)Month (1 - 12 as January to December, also * as every month is allowed)Day of the week (1 - 7 as Monday to Sunday, also * as every day is allowed)
  --enabled: oneof<nothing, bool> # Enabled.
  --id: string # The id of the scheduled task. This value is ignored for creation of new scheduled tasks.
  --script-location: string # Absolute path from this linux hosting to execute.
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/scheduledtasks/{scheduledTaskId}"
    path_params: [{name: domainName, var: domain_name}, {name: scheduledTaskId, var: scheduled_task_id}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: scheduled_task_id, var: qp_scheduled_task_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: cron_expression, var: cron_expression}, {name: enabled, var: enabled}, {name: id, var: id}, {name: script_location, var: script_location}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, scheduled_task_id: $scheduled_task_id, qp_domain_name: $qp_domain_name, qp_scheduled_task_id: $qp_scheduled_task_id, cron_expression: $cron_expression, enabled: $enabled, id: $id, script_location: $script_location
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/disable GZIP compression
#
# PUT /linuxhostings/{domainName}/settings/gzipcompression
# operationId: ChangeGzipCompression
export def "change-gzip-compression" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/settings/gzipcompression"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a host header
#
# POST /linuxhostings/{domainName}/sites/{siteName}/hostheaders
# operationId: CreateHostHeader
export def "create-host-header" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-site-name: string # Name of the site on the linux hosting. (required) (spec name: site_name)
  --body-domain-name: string # Host header domain name (e.g. alias.be or alias.site.be). (spec name: domain_name)
]: any -> any {
  $in | http-request {
    method: post
    path: "/linuxhostings/{domainName}/sites/{siteName}/hostheaders"
    path_params: [{name: domainName, var: domain_name}, {name: siteName, var: site_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: site_name, var: qp_site_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain_name, var: body_domain_name}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, site_name: $site_name, qp_domain_name: $qp_domain_name, qp_site_name: $qp_site_name, body_domain_name: $body_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure HTTP/2
#
# PUT /linuxhostings/{domainName}/sites/{siteName}/http2/configuration
# operationId: ConfigureHttp2
export def "configure-http2" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-site-name: string # Site name where HTTP/2 should be configured. For HTTP/2 to work correctly, the site must have ssl enabled. (required) (spec name: site_name)
  --enabled: oneof<nothing, bool> # Enable or disable HTTP/2.
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/sites/{siteName}/http2/configuration"
    path_params: [{name: domainName, var: domain_name}, {name: siteName, var: site_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: site_name, var: qp_site_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, site_name: $site_name, qp_domain_name: $qp_domain_name, qp_site_name: $qp_site_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure SSH
#
# PUT /linuxhostings/{domainName}/ssh/configuration
# operationId: ConfigureSsh
export def "configure-ssh" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enable or disable SSH.
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/ssh/configuration"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of SSH keys
#
# GET /linuxhostings/{domainName}/ssh/keys
# Returns: table<fingerprint: string, public_key: string>
# operationId: GetSshKeys
export def "get-ssh-keys" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/linuxhostings/{domainName}/ssh/keys"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a SSH key
#
# POST /linuxhostings/{domainName}/ssh/keys
# operationId: AddSshKey
export def "add-ssh-key" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --public-key: string # Public key
]: any -> any {
  $in | http-request {
    method: post
    path: "/linuxhostings/{domainName}/ssh/keys"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: public_key, var: public_key}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, public_key: $public_key
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a SSH key
#
# DELETE /linuxhostings/{domainName}/ssh/keys/{fingerprint}
# operationId: DeleteSshKey
export def "delete-ssh-key" [
  domain_name: string
  fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/linuxhostings/{domainName}/ssh/keys/{fingerprint}"
    path_params: [{name: domainName, var: domain_name}, {name: fingerprint, var: fingerprint}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, fingerprint: $fingerprint, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure auto redirect
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/autoredirect
# operationId: ChangeAutoRedirect
export def "change-auto-redirect" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/sslsettings/{hostname}/autoredirect"
    path_params: [{name: domainName, var: domain_name}, {name: hostname, var: hostname}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, hostname: $hostname, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure let's encrypt
#
# PUT /linuxhostings/{domainName}/sslsettings/{hostname}/letsencrypt
# operationId: ChangeLetsEncrypt
export def "change-lets-encrypt" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/linuxhostings/{domainName}/sslsettings/{hostname}/letsencrypt"
    path_params: [{name: domainName, var: domain_name}, {name: hostname, var: hostname}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, hostname: $hostname, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a subsite
#
# POST /linuxhostings/{domainName}/subsites
# operationId: CreateSubsite
export def "create-subsite" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --body-domain-name: string # Subsite domain name (e.g. alias.be or subsite.site.be). (spec name: domain_name)
  --path: string # Folder location for the subsite (when empty we use /subsites/site (e.g. /subsites/subsite.site.be) The path MUST pre-exist on the server. It WILL NOT be created automatically.
]: any -> any {
  $in | http-request {
    method: post
    path: "/linuxhostings/{domainName}/subsites"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: domain_name, var: body_domain_name}, {name: path, var: path}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, body_domain_name: $body_domain_name, path: $path
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a subsite
#
# DELETE /linuxhostings/{domainName}/subsites/{siteName}
# operationId: DeleteSubsite
export def "delete-subsite" [
  domain_name: string
  site_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Linux hosting domain name. (required) (spec name: domain_name)
  --qp-site-name: string # Name of the site on the linux hosting. (required) (spec name: site_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/linuxhostings/{domainName}/subsites/{siteName}"
    path_params: [{name: domainName, var: domain_name}, {name: siteName, var: site_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: site_name, var: qp_site_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, site_name: $site_name, qp_domain_name: $qp_domain_name, qp_site_name: $qp_site_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Gets your mailboxes.
#
# GET /mailboxes
# Returns: table<actual_size: int, max_size: int, name: string>
# operationId: GetMailboxes
export def "get-mailboxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # Obligated domain name for getting mailboxes. (nullable)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mailboxes"
    query: [{name: domain_name, var: domain_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new mailbox.
#
# POST /mailboxes
# operationId: CreateMailbox
export def "create-mailbox" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # Mail zone account id (format: int32)
  --email-address: string # E-mail address
  --password: string # The password for the mailbox. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  $in | http-request {
    method: post
    path: "/mailboxes"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: email_address, var: email_address}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    account_id: $account_id, email_address: $email_address, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mailbox
#
# DELETE /mailboxes/{mailboxName}
# operationId: DeleteMailbox
export def "delete-mailbox" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-mailbox-name: string # Mailbox name. (required) (spec name: mailbox_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mailboxes/{mailboxName}"
    path_params: [{name: mailboxName, var: mailbox_name}]
    query: [{name: mailbox_name, var: qp_mailbox_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mailbox_name: $mailbox_name, qp_mailbox_name: $qp_mailbox_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific mailbox
#
# GET /mailboxes/{mailboxName}
# Returns: record<actual_size: int, auto_forward: record<copy_to_myself: bool, email_addresses: list<string>, enabled: bool>, auto_reply: record<enabled: bool, message: string, subject: string>, login: string, max_size: int, name: string>
# operationId: GetMailbox
export def "get-mailbox" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-mailbox-name: string # Mailbox name. (required) (spec name: mailbox_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mailboxes/{mailboxName}"
    path_params: [{name: mailboxName, var: mailbox_name}]
    query: [{name: mailbox_name, var: qp_mailbox_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    mailbox_name: $mailbox_name, qp_mailbox_name: $qp_mailbox_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure auto-forward for mailbox
#
# PUT /mailboxes/{mailboxName}/autoforward
# operationId: ConfigureMailboxAutoForward
export def "configure-mailbox-auto-forward" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-mailbox-name: string # Mailbox name. (required) (spec name: mailbox_name)
  --copy-to-myself: oneof<nothing, bool> # Copy to myself
  --email-addresses: list<string> # E-mail addresses to which e-mails are forwarded
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailboxes/{mailboxName}/autoforward"
    path_params: [{name: mailboxName, var: mailbox_name}]
    query: [{name: mailbox_name, var: qp_mailbox_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: copy_to_myself, var: copy_to_myself}, {name: email_addresses, var: email_addresses}, {name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mailbox_name: $mailbox_name, qp_mailbox_name: $qp_mailbox_name, copy_to_myself: $copy_to_myself, email_addresses: $email_addresses, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure auto-reply for mailbox
#
# PUT /mailboxes/{mailboxName}/autoreply
# operationId: ConfigureMailboxAutoReply
export def "configure-mailbox-auto-reply" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-mailbox-name: string # Mailbox name. (required) (spec name: mailbox_name)
  --enabled: oneof<nothing, bool> # Enabled
  --message: string # Message
  --subject: string # Subject
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailboxes/{mailboxName}/autoreply"
    path_params: [{name: mailboxName, var: mailbox_name}]
    query: [{name: mailbox_name, var: qp_mailbox_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}, {name: message, var: message}, {name: subject, var: subject}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mailbox_name: $mailbox_name, qp_mailbox_name: $qp_mailbox_name, enabled: $enabled, message: $message, subject: $subject
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password for mailbox
#
# PUT /mailboxes/{mailboxName}/password
# operationId: ChangeMailboxPassword
export def "change-mailbox-password" [
  mailbox_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-mailbox-name: string # Mailbox name. (required) (spec name: mailbox_name)
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailboxes/{mailboxName}/password"
    path_params: [{name: mailboxName, var: mailbox_name}]
    query: [{name: mailbox_name, var: qp_mailbox_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    mailbox_name: $mailbox_name, qp_mailbox_name: $qp_mailbox_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the mail zone.
#
# GET /mailzones/{domainName}
# Returns: record<aliases: table<destinations: list, email_address: string>, anti_spam: record<allowed_types: list<string>, type: string>, available_accounts: table<account_id: int, size: int>, catch_all: record<email_addresses: list<string>>, enabled: bool, name: string, smtp_domains: table<enabled: bool, hostname: string>>
# operationId: GetMailZone
export def "get-mail-zone" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mailzones/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new alias
#
# POST /mailzones/{domainName}/aliases
# operationId: CreateAlias
export def "create-alias" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --destinations: list<string> # The alias destination e-mail addresses
  --email-address: string # The alias e-mail
]: any -> any {
  $in | http-request {
    method: post
    path: "/mailzones/{domainName}/aliases"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinations, var: destinations}, {name: email_address, var: email_address}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, destinations: $destinations, email_address: $email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a alias
#
# DELETE /mailzones/{domainName}/aliases/{emailAddress}
# operationId: DeleteAlias
export def "delete-alias" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --qp-email-address: string # Alias e-mail address. (required) (spec name: email_address)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mailzones/{domainName}/aliases/{emailAddress}"
    path_params: [{name: domainName, var: domain_name}, {name: emailAddress, var: email_address}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: email_address, var: qp_email_address, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, email_address: $email_address, qp_domain_name: $qp_domain_name, qp_email_address: $qp_email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure a alias
#
# PUT /mailzones/{domainName}/aliases/{emailAddress}
# operationId: ConfigureAlias
export def "configure-alias" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --qp-email-address: string # Alias e-mail address. (required) (spec name: email_address)
  --destinations: list<string> # The alias destination e-mail addresses
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailzones/{domainName}/aliases/{emailAddress}"
    path_params: [{name: domainName, var: domain_name}, {name: emailAddress, var: email_address}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: email_address, var: qp_email_address, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: destinations, var: destinations}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    domain_name: $domain_name, email_address: $email_address, qp_domain_name: $qp_domain_name, qp_email_address: $qp_email_address, destinations: $destinations
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure anti-spam for mail zone
#
# PUT /mailzones/{domainName}/antispam
# operationId: ConfigureAntiSpam
export def "configure-anti-spam" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --type: string@type-completer # Types of anti-spam scanning
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailzones/{domainName}/antispam"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: type, var: type}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a catch-all on the mail zone
#
# POST /mailzones/{domainName}/catchall
# operationId: CreateCatchAll
export def "create-catch-all" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases
]: any -> any {
  $in | http-request {
    method: post
    path: "/mailzones/{domainName}/catchall"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: email_address, var: email_address}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, email_address: $email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a catch-all on the mail zone
#
# DELETE /mailzones/{domainName}/catchall/{emailAddress}
# operationId: DeleteCatchAll
export def "delete-catch-all" [
  domain_name: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --qp-email-address: string # E-mail address to which all e-mails are sent to inexistent mailboxes or aliases. (required) (spec name: email_address)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mailzones/{domainName}/catchall/{emailAddress}"
    path_params: [{name: domainName, var: domain_name}, {name: emailAddress, var: email_address}]
    query: [{name: domain_name, var: qp_domain_name, required: true}, {name: email_address, var: qp_email_address, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, email_address: $email_address, qp_domain_name: $qp_domain_name, qp_email_address: $qp_email_address
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an extra smtp domain
#
# POST /mailzones/{domainName}/smtpdomains
# operationId: CreateSmtpDomain
export def "create-smtp-domain" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --hostname: string # The smtp domain name
]: any -> any {
  $in | http-request {
    method: post
    path: "/mailzones/{domainName}/smtpdomains"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: hostname, var: hostname}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name, hostname: $hostname
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an extra smtp domain
#
# DELETE /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: DeleteSmtpDomain
export def "delete-smtp-domain" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mailzones/{domainName}/smtpdomains/{hostname}"
    path_params: [{name: domainName, var: domain_name}, {name: hostname, var: hostname}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    domain_name: $domain_name, hostname: $hostname, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Configure an extra smtp domain
#
# PUT /mailzones/{domainName}/smtpdomains/{hostname}
# operationId: ConfigureSmtpDomain
export def "configure-smtp-domain" [
  domain_name: string
  hostname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # Mail zone domain name. (required) (spec name: domain_name)
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/mailzones/{domainName}/smtpdomains/{hostname}"
    path_params: [{name: domainName, var: domain_name}, {name: hostname, var: hostname}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    domain_name: $domain_name, hostname: $hostname, qp_domain_name: $qp_domain_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of mysql databases
#
# GET /mysqldatabases
# Returns: table<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int>
# operationId: GetMySqlDatabases
export def "get-my-sql-databases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mysqldatabases"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new mysql database
#
# POST /mysqldatabases
# operationId: CreateMySqlDatabase
export def "create-my-sql-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # The id of the account on which to create the database. (format: int32)
  --database-name: string # The name for the database. This will be prefixed during provisioning. The provided name during creation will be different from the provisioned database name.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  $in | http-request {
    method: post
    path: "/mysqldatabases"
    body: {content_type: "application/json", kind: json, fields: [{name: account_id, var: account_id}, {name: database_name, var: database_name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    account_id: $account_id, database_name: $database_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mysql database
#
# DELETE /mysqldatabases/{databaseName}
# operationId: DeleteDatabase
export def "delete-database" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mysqldatabases/{databaseName}"
    path_params: [{name: databaseName, var: database_name}]
    query: [{name: database_name, var: qp_database_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    database_name: $database_name, qp_database_name: $qp_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a specific database
#
# GET /mysqldatabases/{databaseName}
# Returns: record<account_id: int, actual_size: int, hostname: string, max_size: int, name: string, user_count: int>
# operationId: GetMySqlDatabase
export def "get-my-sql-database" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # required (spec name: database_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/mysqldatabases/{databaseName}"
    path_params: [{name: databaseName, var: database_name}]
    query: [{name: database_name, var: qp_database_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    database_name: $database_name, qp_database_name: $qp_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of mysql users
#
# GET /mysqldatabases/{databaseName}/users
# Returns: table<enabled: bool, name: string, rights: string>
# operationId: GetDatabaseUsers
export def "get-database-users" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/mysqldatabases/{databaseName}/users"
    path_params: [{name: databaseName, var: database_name}]
    query: [{name: database_name, var: qp_database_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    database_name: $database_name, qp_database_name: $qp_database_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new mysql user
#
# POST /mysqldatabases/{databaseName}/users
# operationId: CreateMySqlUser
export def "create-my-sql-user" [
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
  --name: string # User name User names have to adhere to following rules:Between 2-14 characters.Must be a mix of letters and/or digits.Must be lower cased.Cannot contain spaces.
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  $in | http-request {
    method: post
    path: "/mysqldatabases/{databaseName}/users"
    path_params: [{name: databaseName, var: database_name}]
    query: [{name: database_name, var: qp_database_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: name, var: name}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [202]
    auth: bearer
  } {
    database_name: $database_name, qp_database_name: $qp_database_name, name: $name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a mysql user
#
# DELETE /mysqldatabases/{databaseName}/users/{userName}
# operationId: DeleteDatabaseUser
export def "delete-database-user" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
  --qp-user-name: string # Name of the user. (required) (spec name: user_name)
]: nothing -> any {
  http-request {
    method: delete
    path: "/mysqldatabases/{databaseName}/users/{userName}"
    path_params: [{name: databaseName, var: database_name}, {name: userName, var: user_name}]
    query: [{name: database_name, var: qp_database_name, required: true}, {name: user_name, var: qp_user_name, required: true}]
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    database_name: $database_name, user_name: $user_name, qp_database_name: $qp_database_name, qp_user_name: $qp_user_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change password for mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/password
# operationId: ChangeDatabaseUserPassword
export def "change-database-user-password" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
  --qp-user-name: string # Name of the user. (required) (spec name: user_name)
  --password: string # The password for the database user. Passwords have to adhere to following rules:Between 8-20 characters.Must be a mix of letters and digits.Must contain at least one digit (0-9).Must contain at least one letter (a-z).Cannot contain spaces.Cannot contain characters: * € $ & + } { ' " \
]: any -> any {
  $in | http-request {
    method: put
    path: "/mysqldatabases/{databaseName}/users/{userName}/password"
    path_params: [{name: databaseName, var: database_name}, {name: userName, var: user_name}]
    query: [{name: database_name, var: qp_database_name, required: true}, {name: user_name, var: qp_user_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: password, var: password}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    database_name: $database_name, user_name: $user_name, qp_database_name: $qp_database_name, qp_user_name: $qp_user_name, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Enable/disable mysql user
#
# PUT /mysqldatabases/{databaseName}/users/{userName}/status
# operationId: ChangeDatabaseUserStatus
export def "change-database-user-status" [
  database_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-database-name: string # Name of the database. (required) (spec name: database_name)
  --qp-user-name: string # Name of the user. (required) (spec name: user_name)
  --enabled: oneof<nothing, bool> # Enabled
]: any -> any {
  $in | http-request {
    method: put
    path: "/mysqldatabases/{databaseName}/users/{userName}/status"
    path_params: [{name: databaseName, var: database_name}, {name: userName, var: user_name}]
    query: [{name: database_name, var: qp_database_name, required: true}, {name: user_name, var: qp_user_name, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: enabled, var: enabled}]}
    accept: ["application/json"]
    ok: [204]
    auth: bearer
  } {
    database_name: $database_name, user_name: $user_name, qp_database_name: $qp_database_name, qp_user_name: $qp_user_name, enabled: $enabled
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detail of a provisioning job
#
# GET /provisioningjobs/{jobId}
# Returns: record<completion: record<estimate: string>, id: string, status: string>
export def "get-provisioningjobs-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-job-id: string # required, format: uuid (spec name: job_id)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/provisioningjobs/{jobId}"
    path_params: [{name: jobId, var: job_id}]
    query: [{name: job_id, var: qp_job_id, required: true}]
    accept: ["application/json"]
    ok: [200, 201]
    auth: bearer
  } {
    job_id: $job_id, qp_job_id: $qp_job_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of service packs
#
# GET /servicepacks
# Returns: table<id: int, name: string>
# operationId: Servicepacks
export def "servicepacks" [
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
    path: "/servicepacks"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of SSH keys
#
# GET /ssh
# Returns: table<fingerprint: string, linux_hostings: list<string>, public_key: string>
# operationId: GetAllSshKeys
export def "get-all-ssh-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/ssh"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of SSL certificate requests
#
# GET /sslcertificaterequests
# Returns: table<certificate_type: string, common_name: string, id: int, order_code: string, validation_level: string, vendor: string>
# operationId: GetSslCertificateRequests
export def "get-ssl-certificate-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sslcertificaterequests"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Add a SSL certificate request
#
# POST /sslcertificaterequests
# operationId: AddSslCertificateRequest
export def "add-ssl-certificate-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-validation-attributes: list # List of additional validation attributes for the certificate when choosing organization or extended validation. NameInfoRequiredFirstnameFirstname of the technical contactYesLastnameLastname of the technical contactYesPhonePhone of the technical contactYesEmailAddressEmail address of the technical contactYesStreetAddress street of the organizationYesNumberAddress house number of the organizationYesPostalCodeAddress postal code of the organizationYesVatCountryCodeVAT country code of the organization, ISO 3166-1 alpha-2 country codeYesOrganizationNumberBusiness number of the organizationNo — item shape: {name?: string, value?: string}
  --certificate-type: string@certificate-type-completer # The type of the certificate: Standard: Certificate for a single domain.Multi domain: Certificate for multiple (sub)domains belonging to the same owner.Wildcard: Certificate for all the subdomains.
  --csr: string # The certificate signing request data. The certificate signing request subject should contain following attributes:NameCodeFormatCommonNameCNValid domain name, for example site.be, alias.site.be or *.site.beCountryCISO 3166-1 alpha-2 country codeStateSTLocalityLOrganizationOEmailAddressEValid email address The certificate signing request should also contain all the additional aliases and domains (SAN's) for the certificate.
  --validation-level: string@validation-level-completer # The validation level of the certificate: Domain validated: Basic check of the identity of the owner of the domain name.Organization validated: Company details are verified and integrated in the certificate.Extended validated: A thorough verification of your domain name and company details.
]: any -> any {
  $in | http-request {
    method: post
    path: "/sslcertificaterequests"
    body: {content_type: "application/json", kind: json, fields: [{name: additional_validation_attributes, var: additional_validation_attributes}, {name: certificate_type, var: certificate_type}, {name: csr, var: csr}, {name: validation_level, var: validation_level}]}
    accept: ["application/json"]
    ok: [201]
    auth: bearer
  } {
    additional_validation_attributes: $additional_validation_attributes, certificate_type: $certificate_type, csr: $csr, validation_level: $validation_level
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detail of a SSL certificate request
#
# GET /sslcertificaterequests/{id}
# Returns: record<certificate_type: string, common_name: string, id: int, order_code: string, subject_alt_names: table<type: string, value: string>, validation_level: string, validations: table<auto_validated: bool, cname_validation_content: string, cname_validation_name: string, dns_name: string, email_addresses: list, file_validation_content: list, file_validation_url_http: string, file_validation_url_https: string, type: string>, vendor: string>
# operationId: GetSslCertificateRequest
export def "get-ssl-certificate-request" [
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
    path: "/sslcertificaterequests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200, 303]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Verify the SSL certificate request domain validations
#
# PUT /sslcertificaterequests/{id}
# operationId: VerifySslCertificateRequestDomainValidations
export def "verify-ssl-certificate-request-domain-validations" [
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
    path: "/sslcertificaterequests/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [202, 303]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of SSL certificates
#
# GET /sslcertificates
# Returns: table<common_name: string, expires_after: string, sha1_fingerprint: string, type: string, validation_level: string>
# operationId: GetSslCertificates
export def "get-ssl-certificates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/sslcertificates"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Detail of a SSL certificate
#
# GET /sslcertificates/{sha1Fingerprint}
# Returns: record<common_name: string, expires_after: string, sha1_fingerprint: string, subject_alt_names: table<type: string, value: string>, type: string, validation_level: string>
# operationId: GetSslCertificate
export def "get-ssl-certificate" [
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sha1-fingerprint: string # The SHA-1 fingerprint of the certificate. (required) (spec name: sha1_fingerprint)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sslcertificates/{sha1Fingerprint}"
    path_params: [{name: sha1Fingerprint, var: sha1_fingerprint}]
    query: [{name: sha1_fingerprint, var: qp_sha1_fingerprint, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sha1_fingerprint: $sha1_fingerprint, qp_sha1_fingerprint: $qp_sha1_fingerprint
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Download a SSL certificate
#
# GET /sslcertificates/{sha1Fingerprint}/download
# Returns: binary
# operationId: DownloadCertificate
export def "download-certificate" [
  sha1_fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sha1-fingerprint: string # The SHA-1 fingerprint of the certificate. (required) (spec name: sha1_fingerprint)
  --file-format: string@file-format-completer # The file format of the returned file stream: PFX: Also known as PKCS #12, is a single, password protected certificate archive that contains the entire certificate chain plus the matching private key. (required)
  --password: string # The password used to protect the certificate file. (required)
]: nothing -> any {
  http-request {
    method: get
    path: "/sslcertificates/{sha1Fingerprint}/download"
    path_params: [{name: sha1Fingerprint, var: sha1_fingerprint}]
    query: [{name: sha1_fingerprint, var: qp_sha1_fingerprint, required: true}, {name: file_format, var: file_format, required: true, default: pfx}, {name: password, var: password, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sha1_fingerprint: $sha1_fingerprint, qp_sha1_fingerprint: $qp_sha1_fingerprint, file_format: $file_format, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Overview of windows hostings
#
# GET /windowshostings
# Returns: table<domain_name: string, servicepack_id: int>
# operationId: GetWindowsHostings
export def "get-windows-hostings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of items to skip in the resultset. (format: int32)
  --take: int # The number of items to return in the resultset. The returned count can be equal or less than this number. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/windowshostings"
    query: [{name: skip, var: skip}, {name: take, var: take}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    skip: $skip, take: $take
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Windows hosting detail
#
# GET /windowshostings/{domainName}
# Returns: record<actual_size: int, application_pool: record<installed_net_core_runtimes: list<string>, pipeline_mode: string, runtime: string>, domain_name: string, ftp_username: string, ip: string, ip_type: string, max_size: int, mssql_database_names: list<string>, servicepack_id: int, sites: table<bindings: list, name: string, path: string>>
# operationId: GetWindowsHosting
export def "get-windows-hosting" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-domain-name: string # The Windows hosting domain name. (required) (spec name: domain_name)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/windowshostings/{domainName}"
    path_params: [{name: domainName, var: domain_name}]
    query: [{name: domain_name, var: qp_domain_name, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    domain_name: $domain_name, qp_domain_name: $qp_domain_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
