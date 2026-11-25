# Auto-generated client for OS Config API v1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/osconfig/v1beta/openapi.json
# Auth: --token flag or $env.OS_CONFIG_API_TOKEN

const CLIENT = {
  base_url: "https://osconfig.googleapis.com"
  token_env_var: "OS_CONFIG_API_TOKEN"
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

def base-url-completer [] { ["https://osconfig.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    osconfig-projects-zones-instances-lookup-effective-guest-policy: "record<packageRepositories: table<packageRepository: record, source: string>, packages: table<package: record, source: string>, softwareRecipes: table<softwareRecipe: record, source: string>>"
    osconfig-projects-patch-deployments-delete: "record"
    osconfig-projects-patch-jobs-get: "record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-patch-deployments-patch: "record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-patch-jobs-cancel: "record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-patch-deployments-pause: "record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-patch-deployments-resume: "record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-guest-policies-list: "record<guestPolicies: table<assignment: record, createTime: string, description: string, etag: string, name: string, packageRepositories: list, packages: list, recipes: list, updateTime: string>, nextPageToken: string>"
    osconfig-projects-guest-policies-create: "record<assignment: record<groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, osTypes: list<record>, zones: list<string>>, createTime: string, description: string, etag: string, name: string, packageRepositories: table<apt: record, goo: record, yum: record, zypper: record>, packages: table<desiredState: string, manager: string, name: string>, recipes: table<artifacts: list, desiredState: string, installSteps: list, name: string, updateSteps: list, version: string>, updateTime: string>"
    osconfig-projects-patch-jobs-instance-details-list: "record<nextPageToken: string, patchJobInstanceDetails: table<attemptCount: string, failureReason: string, instanceSystemId: string, name: string, state: string>>"
    osconfig-projects-patch-deployments-list: "record<nextPageToken: string, patchDeployments: table<createTime: string, description: string, duration: string, instanceFilter: record, lastExecuteTime: string, name: string, oneTimeSchedule: record, patchConfig: record, recurringSchedule: record, rollout: record, state: string, updateTime: string>>"
    osconfig-projects-patch-deployments-create: "record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
    osconfig-projects-patch-jobs-list: "record<nextPageToken: string, patchJobs: table<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record, instanceFilter: record, name: string, patchConfig: record, patchDeployment: string, percentComplete: float, rollout: record, state: string, updateTime: string>>"
    osconfig-projects-patch-jobs-execute: "record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["osconfig-projects-zones-instances-lookup-effective-guest-policy" "osconfig-projects-patch-deployments-delete" "osconfig-projects-patch-jobs-get" "osconfig-projects-patch-deployments-patch" "osconfig-projects-patch-jobs-cancel" "osconfig-projects-patch-deployments-pause" "osconfig-projects-patch-deployments-resume" "osconfig-projects-guest-policies-list" "osconfig-projects-guest-policies-create" "osconfig-projects-patch-jobs-instance-details-list" "osconfig-projects-patch-deployments-list" "osconfig-projects-patch-deployments-create" "osconfig-projects-patch-jobs-list" "osconfig-projects-patch-jobs-execute" "commands"] | sort) } | get name | first)
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

# Lookup the effective guest policy that applies to a VM instance. This lookup merges all policies that are assigned to the instance ancestry.
#
# POST /v1beta/{instance}:lookupEffectiveGuestPolicy
# Returns: record<packageRepositories: table<packageRepository: record, source: string>, packages: table<package: record, source: string>, softwareRecipes: table<softwareRecipe: record, source: string>>
# operationId: osconfig.projects.zones.instances.lookupEffectiveGuestPolicy
export def "osconfig-projects-zones-instances-lookup-effective-guest-policy" [
  instance: string
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
  --os-architecture: string # Architecture of OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --os-short-name: string # Short name of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --os-version: string # Version of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that VM instance.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{instance}:lookupEffectiveGuestPolicy"
    path_params: [{name: instance, var: instance}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: osArchitecture, var: os_architecture}, {name: osShortName, var: os_short_name}, {name: osVersion, var: os_version}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    instance: $instance, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, os_architecture: $os_architecture, os_short_name: $os_short_name, os_version: $os_version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an OS Config patch deployment.
#
# DELETE /v1beta/{name}
# Returns: record
# operationId: osconfig.projects.patchDeployments.delete
export def "osconfig-projects-patch-deployments-delete" [
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
    method: delete
    path: "/v1beta/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the patch job. This can be used to track the progress of an ongoing patch job or review the details of completed jobs.
#
# GET /v1beta/{name}
# Returns: record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchJobs.get
export def "osconfig-projects-patch-jobs-get" [
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
    path: "/v1beta/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an OS Config patch deployment.
#
# PATCH /v1beta/{name}
# Returns: record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchDeployments.patch
export def "osconfig-projects-patch-deployments-patch" [
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
  --update-mask: string # Optional. Field mask that controls which fields of the patch deployment should be updated.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --body-name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment. (spec name: name)
  --one-time-schedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurring-schedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1beta/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: updateMask, var: update_mask}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: duration, var: duration}, {name: instanceFilter, var: instance_filter}, {name: name, var: body_name}, {name: oneTimeSchedule, var: one_time_schedule}, {name: patchConfig, var: patch_config}, {name: recurringSchedule, var: recurring_schedule}, {name: rollout, var: rollout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, update_mask: $update_mask, description: $description, duration: $duration, instance_filter: $instance_filter, body_name: $body_name, one_time_schedule: $one_time_schedule, patch_config: $patch_config, recurring_schedule: $recurring_schedule, rollout: $rollout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Cancel a patch job. The patch job must be active. Canceled patch jobs cannot be restarted.
#
# POST /v1beta/{name}:cancel
# Returns: record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchJobs.cancel
export def "osconfig-projects-patch-jobs-cancel" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{name}:cancel"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change state of patch deployment to "PAUSED". Patch deployment in paused state doesn't generate patch jobs.
#
# POST /v1beta/{name}:pause
# Returns: record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchDeployments.pause
export def "osconfig-projects-patch-deployments-pause" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{name}:pause"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Change state of patch deployment back to "ACTIVE". Patch deployment in active state continues to generate patch jobs.
#
# POST /v1beta/{name}:resume
# Returns: record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchDeployments.resume
export def "osconfig-projects-patch-deployments-resume" [
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
  --body: record
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{name}:resume"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a page of OS Config guest policies.
#
# GET /v1beta/{parent}/guestPolicies
# Returns: record<guestPolicies: table<assignment: record, createTime: string, description: string, etag: string, name: string, packageRepositories: list, packages: list, recipes: list, updateTime: string>, nextPageToken: string>
# operationId: osconfig.projects.guestPolicies.list
export def "osconfig-projects-guest-policies-list" [
  parent: string
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
  --page-size: int # The maximum number of guest policies to return.
  --page-token: string # A pagination token returned from a previous call to `ListGuestPolicies` that indicates where this listing should continue from.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/{parent}/guestPolicies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an OS Config guest policy.
#
# POST /v1beta/{parent}/guestPolicies
# Returns: record<assignment: record<groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, osTypes: list<record>, zones: list<string>>, createTime: string, description: string, etag: string, name: string, packageRepositories: table<apt: record, goo: record, yum: record, zypper: record>, packages: table<desiredState: string, manager: string, name: string>, recipes: table<artifacts: list, desiredState: string, installSteps: list, name: string, updateSteps: list, version: string>, updateTime: string>
# operationId: osconfig.projects.guestPolicies.create
export def "osconfig-projects-guest-policies-create" [
  parent: string
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
  --guest-policy-id: string # Required. The logical name of the guest policy in the project with the following restrictions: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --assignment: record # An assignment represents the group or groups of VM instances that the policy applies to. If an assignment is empty, it applies to all VM instances. Otherwise, the targeted VM instances must meet all the criteria specified. So if both labels and zones are specified, the policy applies to VM instances with those labels and in those zones. — shape: {groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, osTypes?: list, zones?: list<string>}
  --description: string # Description of the guest policy. Length of the description is limited to 1024 characters.
  --etag: string # The etag for this guest policy. If this is provided on update, it must match the server's etag.
  --name: string # Required. Unique name of the resource in this project using one of the following forms: `projects/{project_number}/guestPolicies/{guest_policy_id}`.
  --package-repositories: list # A list of package repositories to configure on the VM instance. This is done before any other configs are applied so they can use these repos. Package repositories are only configured if the corresponding package manager(s) are available. — item shape: {apt?: record, goo?: record, yum?: record, zypper?: record}
  --packages: list # The software packages to be managed by this policy. — item shape: {desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", manager?: "MANAGER_UNSPECIFIED"|"ANY"|"APT"|"YUM"|"ZYPPER"|"GOO", name?: string}
  --recipes: list # A list of Recipes to install on the VM instance. — item shape: {artifacts?: list, desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", installSteps?: list, name?: string, updateSteps?: list, version?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{parent}/guestPolicies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: guestPolicyId, var: guest_policy_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: assignment, var: assignment}, {name: description, var: description}, {name: etag, var: etag}, {name: name, var: name}, {name: packageRepositories, var: package_repositories}, {name: packages, var: packages}, {name: recipes, var: recipes}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, guest_policy_id: $guest_policy_id, assignment: $assignment, description: $description, etag: $etag, name: $name, package_repositories: $package_repositories, packages: $packages, recipes: $recipes
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of instance details for a given patch job.
#
# GET /v1beta/{parent}/instanceDetails
# Returns: record<nextPageToken: string, patchJobInstanceDetails: table<attemptCount: string, failureReason: string, instanceSystemId: string, name: string, state: string>>
# operationId: osconfig.projects.patchJobs.instanceDetails.list
export def "osconfig-projects-patch-jobs-instance-details-list" [
  parent: string
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
  --filter: string # A filter expression that filters results listed in the response. This field supports filtering results by instance zone, name, state, or `failure_reason`.
  --page-size: int # The maximum number of instance details records to return. Default is 100.
  --page-token: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/{parent}/instanceDetails"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a page of OS Config patch deployments.
#
# GET /v1beta/{parent}/patchDeployments
# Returns: record<nextPageToken: string, patchDeployments: table<createTime: string, description: string, duration: string, instanceFilter: record, lastExecuteTime: string, name: string, oneTimeSchedule: record, patchConfig: record, recurringSchedule: record, rollout: record, state: string, updateTime: string>>
# operationId: osconfig.projects.patchDeployments.list
export def "osconfig-projects-patch-deployments-list" [
  parent: string
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
  --page-size: int # Optional. The maximum number of patch deployments to return. Default is 100.
  --page-token: string # Optional. A pagination token returned from a previous call to ListPatchDeployments that indicates where this listing should continue from.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/{parent}/patchDeployments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an OS Config patch deployment.
#
# POST /v1beta/{parent}/patchDeployments
# Returns: record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchDeployments.create
export def "osconfig-projects-patch-deployments-create" [
  parent: string
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
  --patch-deployment-id: string # Required. A name for the patch deployment in the project. When creating a name the following rules apply: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment.
  --one-time-schedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurring-schedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{parent}/patchDeployments"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: patchDeploymentId, var: patch_deployment_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: duration, var: duration}, {name: instanceFilter, var: instance_filter}, {name: name, var: name}, {name: oneTimeSchedule, var: one_time_schedule}, {name: patchConfig, var: patch_config}, {name: recurringSchedule, var: recurring_schedule}, {name: rollout, var: rollout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, patch_deployment_id: $patch_deployment_id, description: $description, duration: $duration, instance_filter: $instance_filter, name: $name, one_time_schedule: $one_time_schedule, patch_config: $patch_config, recurring_schedule: $recurring_schedule, rollout: $rollout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of patch jobs.
#
# GET /v1beta/{parent}/patchJobs
# Returns: record<nextPageToken: string, patchJobs: table<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record, instanceFilter: record, name: string, patchConfig: record, patchDeployment: string, percentComplete: float, rollout: record, state: string, updateTime: string>>
# operationId: osconfig.projects.patchJobs.list
export def "osconfig-projects-patch-jobs-list" [
  parent: string
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
  --filter: string # If provided, this field specifies the criteria that must be met by patch jobs to be included in the response. Currently, filtering is only available on the patch_deployment field.
  --page-size: int # The maximum number of instance status to return.
  --page-token: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1beta/{parent}/patchJobs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Patch VM instances by creating and running a patch job.
#
# POST /v1beta/{parent}/patchJobs:execute
# Returns: record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string>
# operationId: osconfig.projects.patchJobs.execute
export def "osconfig-projects-patch-jobs-execute" [
  parent: string
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
  --description: string # Description of the patch job. Length of the description is limited to 1024 characters.
  --display-name: string # Display name for this patch job. This does not have to be unique.
  --body-dry-run: oneof<nothing, bool> # If this patch is a dry-run only, instances are contacted but will do nothing. (spec name: dryRun)
  --duration: string # Duration of the patch job. After the duration ends, the patch job times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1beta/{parent}/patchJobs:execute"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: displayName, var: display_name}, {name: dryRun, var: body_dry_run}, {name: duration, var: duration}, {name: instanceFilter, var: instance_filter}, {name: patchConfig, var: patch_config}, {name: rollout, var: rollout}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, description: $description, display_name: $display_name, body_dry_run: $body_dry_run, duration: $duration, instance_filter: $instance_filter, patch_config: $patch_config, rollout: $rollout
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
