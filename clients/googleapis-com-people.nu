# Auto-generated client for People API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/people/v1/openapi.json
# Auth: --token flag or $env.PEOPLE_API_TOKEN

const CLIENT = {
  base_url: "https://people.googleapis.com"
  token_env_var: "PEOPLE_API_TOKEN"
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

def base-url-completer [] { ["https://people.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def sort-order-completer [] { ["FIRST_NAME_ASCENDING" "LAST_MODIFIED_ASCENDING" "LAST_MODIFIED_DESCENDING" "LAST_NAME_ASCENDING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    people-contact-groups-list: "record<contactGroups: table<clientData: list, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list, metadata: record, name: string, resourceName: string>, nextPageToken: string, nextSyncToken: string, totalItems: int>"
    people-contact-groups-create: "record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string>"
    people-contact-groups-batch-get: "record<responses: table<contactGroup: record, requestedResourceName: string, status: record>>"
    people-other-contacts-list: "record<nextPageToken: string, nextSyncToken: string, otherContacts: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int>"
    people-other-contacts-search: "record<results: table<person: record>>"
    people-people-batch-create-contacts: "record<createdPeople: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>>"
    people-people-batch-delete-contacts: "record"
    people-people-get-batch-get: "record<responses: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>>"
    people-people-batch-update-contacts: "record<updateResult: record>"
    people-people-create-contact: "record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>"
    people-people-list-directory-people: "record<nextPageToken: string, nextSyncToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>>"
    people-people-search-contacts: "record<results: table<person: record>>"
    people-people-search-directory-people: "record<nextPageToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int>"
    people-contact-groups-delete: "record"
    people-people-get: "record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>"
    people-contact-groups-update: "record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string>"
    people-people-connections-list: "record<connections: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, nextPageToken: string, nextSyncToken: string, totalItems: int, totalPeople: int>"
    people-contact-groups-members-modify: "record<canNotRemoveLastContactGroupResourceNames: list<string>, notFoundResourceNames: list<string>>"
    people-other-contacts-copy-other-contact-to-my-contacts-group: "record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>"
    people-people-delete-contact: "record"
    people-people-delete-contact-photo: "record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>>"
    people-people-update-contact: "record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>"
    people-people-update-contact-photo: "record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["people-contact-groups-list" "people-contact-groups-create" "people-contact-groups-batch-get" "people-other-contacts-list" "people-other-contacts-search" "people-people-batch-create-contacts" "people-people-batch-delete-contacts" "people-people-get-batch-get" "people-people-batch-update-contacts" "people-people-create-contact" "people-people-list-directory-people" "people-people-search-contacts" "people-people-search-directory-people" "people-contact-groups-delete" "people-people-get" "people-contact-groups-update" "people-people-connections-list" "people-contact-groups-members-modify" "people-other-contacts-copy-other-contact-to-my-contacts-group" "people-people-delete-contact" "people-people-delete-contact-photo" "people-people-update-contact" "people-people-update-contact-photo" "commands"] | sort) } | get name | first)
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

# List all contact groups owned by the authenticated user. Members of the contact groups are not populated.
#
# GET /v1/contactGroups
# Returns: record<contactGroups: table<clientData: list, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list, metadata: record, name: string, resourceName: string>, nextPageToken: string, nextSyncToken: string, totalItems: int>
# operationId: people.contactGroups.list
export def "people-contact-groups-list" [
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
  --group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, `memberCount`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name
  --page-size: int # Optional. The maximum number of resources to return. Valid values are between 1 and 1000, inclusive. Defaults to 30 if not set or set to 0.
  --page-token: string # Optional. The next_page_token value returned from a previous call to [ListContactGroups](/people/api/rest/v1/contactgroups/list). Requests the next page of resources.
  --sync-token: string # Optional. A sync token, returned by a previous call to `contactgroups.list`. Only resources changed since the sync token was created will be returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/contactGroups"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: groupFields, var: group_fields}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, group_fields: $group_fields, page_size: $page_size, page_token: $page_token, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contact group owned by the authenticated user. Created contact group names must be unique to the users contact groups. Attempting to create a group with a duplicate name will return a HTTP 409 error. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/contactGroups
# Returns: record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string>
# operationId: people.contactGroups.create
export def "people-contact-groups-create" [
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
  --contact-group: record # A contact group. — shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
  --read-group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * metadata * name (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/contactGroups"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactGroup, var: contact_group}, {name: readGroupFields, var: read_group_fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contact_group: $contact_group, read_group_fields: $read_group_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a list of contact groups owned by the authenticated user by specifying a list of contact group resource names.
#
# GET /v1/contactGroups:batchGet
# Returns: record<responses: table<contactGroup: record, requestedResourceName: string, status: record>>
# operationId: people.contactGroups.batchGet
export def "people-contact-groups-batch-get" [
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
  --group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, `memberCount`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name
  --max-members: int # Optional. Specifies the maximum number of members to return for each group. Defaults to 0 if not set, which will return zero members.
  --resource-names: list<string> # Required. The resource names of the contact groups to get. There is a maximum of 200 resource names.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/contactGroups:batchGet"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: groupFields, var: group_fields}, {name: maxMembers, var: max_members}, {name: resourceNames, var: resource_names, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, group_fields: $group_fields, max_members: $max_members, resource_names: $resource_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List all "Other contacts", that is contacts that are not in a contact group. "Other contacts" are typically auto created contacts from interactions. Sync tokens expire 7 days after the full sync. A request with an expired sync token will get an error with an [google.rpc.ErrorInfo](https://cloud.google.com/apis/design/errors#error_info) with reason "EXPIRED_SYNC_TOKEN". In the case of such an error clients should make a full sync request without a `sync_token`. The first page of a full sync request has an additional quota. If the quota is exceeded, a 429 error will be returned. This quota is fixed and can not be increased. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the user's other contacts that have changed](/people/v1/other-contacts#list_the_users_other_contacts_that_have_changed).
#
# GET /v1/otherContacts
# Returns: record<nextPageToken: string, nextSyncToken: string, otherContacts: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int>
# operationId: people.otherContacts.list
export def "people-other-contacts-list" [
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
  --page-size: int # Optional. The number of "Other contacts" to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `otherContacts.list` must match the first call that provided the page token.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. What values are valid depend on what ReadSourceType is used. If READ_SOURCE_TYPE_CONTACT is used, valid values are: * emailAddresses * metadata * names * phoneNumbers * photos If READ_SOURCE_TYPE_PROFILE is used, valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token` on the last page of results. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `otherContacts.list`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT if not set. Possible values for this field are: * READ_SOURCE_TYPE_CONTACT * READ_SOURCE_TYPE_CONTACT,READ_SOURCE_TYPE_PROFILE Specifying READ_SOURCE_TYPE_PROFILE without specifying READ_SOURCE_TYPE_CONTACT is not permitted.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `otherContacts.list` must match the first call that provided the sync token. More details about sync behavior at `otherContacts.list`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/otherContacts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}, {name: requestSyncToken, var: request_sync_token}, {name: sources, var: sources, style: multi}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, read_mask: $read_mask, request_sync_token: $request_sync_token, sources: $sources, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of contacts in the authenticated user's other contacts that matches the search query. The query matches on a contact's `names`, `emailAddresses`, and `phoneNumbers` fields that are from the OTHER_CONTACT source. **IMPORTANT**: Before searching, clients should send a warmup request with an empty query to update the cache. See https://developers.google.com/people/v1/other-contacts#search_the_users_other_contacts
#
# GET /v1/otherContacts:search
# Returns: record<results: table<person: record>>
# operationId: people.otherContacts.search
export def "people-other-contacts-search" [
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
  --page-size: int # Optional. The number of results to return. Defaults to 10 if field is not set, or set to 0. Values greater than 30 will be capped to 30.
  --query: string # Required. The plain-text query for the request. The query is used to match prefix phrases of the fields on a person. For example, a person with name "foo name" matches queries such as "f", "fo", "foo", "foo n", "nam", etc., but not "oo n".
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * emailAddresses * metadata * names * phoneNumbers
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/otherContacts:search"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: readMask, var: read_mask}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, query: $query, read_mask: $read_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a batch of new contacts and return the PersonResponses for the newly Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchCreateContacts
# Returns: record<createdPeople: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>>
# operationId: people.people.batchCreateContacts
export def "people-people-batch-create-contacts" [
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
  --contacts: list # Required. The contact to create. Allows up to 200 contacts in a single request. — item shape: {contactPerson?: record}
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned in the response. Multiple fields can be specified by separating them with commas. If read mask is left empty, the post-mutate-get is skipped and no data will be returned in the response. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return in the post mutate read. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/people:batchCreateContacts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contacts, var: contacts}, {name: readMask, var: read_mask}, {name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contacts: $contacts, read_mask: $read_mask, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a batch of contacts. Any non-contact data will not be deleted. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchDeleteContacts
# Returns: record
# operationId: people.people.batchDeleteContacts
export def "people-people-batch-delete-contacts" [
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
  --resource-names: list<string> # Required. The resource names of the contact to delete. It's repeatable. Allows up to 500 resource names in a single request.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/people:batchDeleteContacts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceNames, var: resource_names}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, resource_names: $resource_names
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about a list of specific people by specifying a list of requested resource names. Use `people/me` to indicate the authenticated user. The request returns a 400 error if 'personFields' is not specified.
#
# GET /v1/people:batchGet
# Returns: record<responses: table<httpStatusCode: int, person: record, requestedResourceName: string, status: record>>
# operationId: people.people.getBatchGet
export def "people-people-get-batch-get" [
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
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --resource-names: list<string> # Required. The resource names of the people to provide information about. It's repeatable. The URL query parameter should be resourceNames=&resourceNames=&... - To get information about the authenticated user, specify `people/me`. - To get information about a google account, specify `people/{account_id}`. - To get information about a contact, specify the resource name that identifies the contact as returned by `people.connections.list`. There is a maximum of 200 resource names.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/people:batchGet"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: personFields, var: person_fields}, {name: "requestMask.includeField", var: request_mask_include_field}, {name: resourceNames, var: resource_names, style: multi}, {name: sources, var: sources, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, request_mask_include_field: $request_mask_include_field, resource_names: $resource_names, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a batch of contacts and return a map of resource names to PersonResponses for the updated contacts. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:batchUpdateContacts
# Returns: record<updateResult: record>
# operationId: people.people.batchUpdateContacts
export def "people-people-batch-update-contacts" [
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
  --contacts: record # Required. A map of resource names to the person data to be updated. Allows up to 200 contacts in a single request.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. If read mask is left empty, the post-mutate-get is skipped and no data will be returned in the response. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --update-mask: string # Required. A field mask to restrict which fields on the person are updated. Multiple fields can be specified by separating them with commas. All specified fields will be replaced, or cleared if left empty for each person. Valid values are: * addresses * biographies * birthdays * calendarUrls * clientData * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * relations * sipAddresses * urls * userDefined (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/people:batchUpdateContacts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contacts, var: contacts}, {name: readMask, var: read_mask}, {name: sources, var: sources}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contacts: $contacts, read_mask: $read_mask, sources: $sources, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a new contact and return the person resource for that contact. The request returns a 400 error if more than one field is specified on a field that is a singleton for contact sources: * biographies * birthdays * genders * names Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/people:createContact
# Returns: record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>
# operationId: people.people.createContact
export def "people-people-create-contact" [
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
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Defaults to all fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --addresses: list # The person's street addresses. — item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --biographies: list # The person's biographies. This field is a singleton for contact sources. — item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
  --birthdays: list # The person's birthdays. This field is a singleton for contact sources. — item shape: {date?: record, metadata?: record, text?: string}
  --bragging-rights: list # **DEPRECATED**: No data will be returned The person's bragging rights. — item shape: {metadata?: record, value?: string}
  --calendar-urls: list # The person's calendar URLs. — item shape: {metadata?: record, type?: string, url?: string}
  --client-data: list # The person's client data. — item shape: {key?: string, metadata?: record, value?: string}
  --email-addresses: list # The person's email addresses. For `people.connections.list` and `otherContacts.list` the number of email addresses is limited to 100. If a Person has more email addresses the entire set can be obtained by calling GetPeople. — item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
  --etag: string # The [HTTP entity tag](https://en.wikipedia.org/wiki/HTTP_ETag) of the resource. Used for web cache validation.
  --events: list # The person's events. — item shape: {date?: record, metadata?: record, type?: string}
  --external-ids: list # The person's external IDs. — item shape: {metadata?: record, type?: string, value?: string}
  --file-ases: list # The person's file-ases. — item shape: {metadata?: record, value?: string}
  --genders: list # The person's genders. This field is a singleton for contact sources. — item shape: {addressMeAs?: string, metadata?: record, value?: string}
  --im-clients: list # The person's instant messaging clients. — item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
  --interests: list # The person's interests. — item shape: {metadata?: record, value?: string}
  --locales: list # The person's locale preferences. — item shape: {metadata?: record, value?: string}
  --locations: list # The person's locations. — item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
  --memberships: list # The person's group memberships. — item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
  --metadata: record # The metadata about a person. — shape: {sources?: list}
  --misc-keywords: list # The person's miscellaneous keywords. — item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
  --names: list # The person's names. This field is a singleton for contact sources. — item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
  --nicknames: list # The person's nicknames. — item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
  --occupations: list # The person's occupations. — item shape: {metadata?: record, value?: string}
  --organizations: list # The person's past or current organizations. — item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
  --phone-numbers: list # The person's phone numbers. For `people.connections.list` and `otherContacts.list` the number of phone numbers is limited to 100. If a Person has more phone numbers the entire set can be obtained by calling GetPeople. — item shape: {metadata?: record, type?: string, value?: string}
  --relations: list # The person's relations. — item shape: {metadata?: record, person?: string, type?: string}
  --residences: list # **DEPRECATED**: (Please use `person.locations` instead) The person's residences. — item shape: {current?: bool, metadata?: record, value?: string}
  --resource-name: string # The resource name for the person, assigned by the server. An ASCII string in the form of `people/{person_id}`.
  --sip-addresses: list # The person's SIP addresses. — item shape: {metadata?: record, type?: string, value?: string}
  --skills: list # The person's skills. — item shape: {metadata?: record, value?: string}
  --urls: list # The person's associated URLs. — item shape: {metadata?: record, type?: string, value?: string}
  --user-defined: list # The person's user defined data. — item shape: {key?: string, metadata?: record, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/people:createContact"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: personFields, var: person_fields}, {name: sources, var: sources, style: multi}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: biographies, var: biographies}, {name: birthdays, var: birthdays}, {name: braggingRights, var: bragging_rights}, {name: calendarUrls, var: calendar_urls}, {name: clientData, var: client_data}, {name: emailAddresses, var: email_addresses}, {name: etag, var: etag}, {name: events, var: events}, {name: externalIds, var: external_ids}, {name: fileAses, var: file_ases}, {name: genders, var: genders}, {name: imClients, var: im_clients}, {name: interests, var: interests}, {name: locales, var: locales}, {name: locations, var: locations}, {name: memberships, var: memberships}, {name: metadata, var: metadata}, {name: miscKeywords, var: misc_keywords}, {name: names, var: names}, {name: nicknames, var: nicknames}, {name: occupations, var: occupations}, {name: organizations, var: organizations}, {name: phoneNumbers, var: phone_numbers}, {name: relations, var: relations}, {name: residences, var: residences}, {name: resourceName, var: resource_name}, {name: sipAddresses, var: sip_addresses}, {name: skills, var: skills}, {name: urls, var: urls}, {name: userDefined, var: user_defined}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, sources: $sources, addresses: $addresses, biographies: $biographies, birthdays: $birthdays, bragging_rights: $bragging_rights, calendar_urls: $calendar_urls, client_data: $client_data, email_addresses: $email_addresses, etag: $etag, events: $events, external_ids: $external_ids, file_ases: $file_ases, genders: $genders, im_clients: $im_clients, interests: $interests, locales: $locales, locations: $locations, memberships: $memberships, metadata: $metadata, misc_keywords: $misc_keywords, names: $names, nicknames: $nicknames, occupations: $occupations, organizations: $organizations, phone_numbers: $phone_numbers, relations: $relations, residences: $residences, resource_name: $resource_name, sip_addresses: $sip_addresses, skills: $skills, urls: $urls, user_defined: $user_defined
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of domain profiles and domain contacts in the authenticated user's domain directory. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the directory people that have changed](/people/v1/directory#list_the_directory_people_that_have_changed).
#
# GET /v1/people:listDirectoryPeople
# Returns: record<nextPageToken: string, nextSyncToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>>
# operationId: people.people.listDirectoryPeople
export def "people-people-list-directory-people" [
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
  --merge-sources: list<string> # Optional. Additional data to merge into the directory sources if they are connected through verified join keys such as email addresses or phone numbers.
  --page-size: int # Optional. The number of people to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `people.listDirectoryPeople` must match the first call that provided the page token.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token`. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `people.listDirectoryPeople`.
  --sources: list<string> # Required. Directory sources to return.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `people.listDirectoryPeople` must match the first call that provided the sync token. More details about sync behavior at `people.listDirectoryPeople`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/people:listDirectoryPeople"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: mergeSources, var: merge_sources, style: multi}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: readMask, var: read_mask}, {name: requestSyncToken, var: request_sync_token}, {name: sources, var: sources, style: multi}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, merge_sources: $merge_sources, page_size: $page_size, page_token: $page_token, read_mask: $read_mask, request_sync_token: $request_sync_token, sources: $sources, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of contacts in the authenticated user's grouped contacts that matches the search query. The query matches on a contact's `names`, `nickNames`, `emailAddresses`, `phoneNumbers`, and `organizations` fields that are from the CONTACT source. **IMPORTANT**: Before searching, clients should send a warmup request with an empty query to update the cache. See https://developers.google.com/people/v1/contacts#search_the_users_contacts
#
# GET /v1/people:searchContacts
# Returns: record<results: table<person: record>>
# operationId: people.people.searchContacts
export def "people-people-search-contacts" [
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
  --page-size: int # Optional. The number of results to return. Defaults to 10 if field is not set, or set to 0. Values greater than 30 will be capped to 30.
  --query: string # Required. The plain-text query for the request. The query is used to match prefix phrases of the fields on a person. For example, a person with name "foo name" matches queries such as "f", "fo", "foo", "foo n", "nam", etc., but not "oo n".
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT if not set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/people:searchContacts"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: readMask, var: read_mask}, {name: sources, var: sources, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, query: $query, read_mask: $read_mask, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of domain profiles and domain contacts in the authenticated user's domain directory that match the search query.
#
# GET /v1/people:searchDirectoryPeople
# Returns: record<nextPageToken: string, people: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, totalSize: int>
# operationId: people.people.searchDirectoryPeople
export def "people-people-search-directory-people" [
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
  --merge-sources: list<string> # Optional. Additional data to merge into the directory sources if they are connected through verified join keys such as email addresses or phone numbers.
  --page-size: int # Optional. The number of people to include in the response. Valid values are between 1 and 500, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `SearchDirectoryPeople` must match the first call that provided the page token.
  --query: string # Required. Prefix query that matches fields in the person. Does NOT use the read_mask for determining what fields to match.
  --read-mask: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Required. Directory sources to return.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/people:searchDirectoryPeople"
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: mergeSources, var: merge_sources, style: multi}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: query, var: query}, {name: readMask, var: read_mask}, {name: sources, var: sources, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, merge_sources: $merge_sources, page_size: $page_size, page_token: $page_token, query: $query, read_mask: $read_mask, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete an existing contact group owned by the authenticated user by specifying a contact group resource name. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# DELETE /v1/{resourceName}
# Returns: record
# operationId: people.contactGroups.delete
export def "people-contact-groups-delete" [
  resource_name: string
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
  --delete-contacts: oneof<nothing, bool> # Optional. Set to true to also delete the contacts in the specified group.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{resourceName}"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: deleteContacts, var: delete_contacts}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, delete_contacts: $delete_contacts
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides information about a person by specifying a resource name. Use `people/me` to indicate the authenticated user. The request returns a 400 error if 'personFields' is not specified.
#
# GET /v1/{resourceName}
# Returns: record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>
# operationId: people.people.get
export def "people-people-get" [
  resource_name: string
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
  --person-fields: string # Required. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_PROFILE and READ_SOURCE_TYPE_CONTACT if not set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{resourceName}"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: personFields, var: person_fields}, {name: "requestMask.includeField", var: request_mask_include_field}, {name: sources, var: sources, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, request_mask_include_field: $request_mask_include_field, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update the name of an existing contact group owned by the authenticated user. Updated contact group names must be unique to the users contact groups. Attempting to create a group with a duplicate name will return a HTTP 409 error. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PUT /v1/{resourceName}
# Returns: record<clientData: table<key: string, value: string>, etag: string, formattedName: string, groupType: string, memberCount: int, memberResourceNames: list<string>, metadata: record<deleted: bool, updateTime: string>, name: string, resourceName: string>
# operationId: people.contactGroups.update
export def "people-contact-groups-update" [
  resource_name: string
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
  --contact-group: record # A contact group. — shape: {clientData?: list, etag?: string, metadata?: record, name?: string, resourceName?: string}
  --read-group-fields: string # Optional. A field mask to restrict which fields on the group are returned. Defaults to `metadata`, `groupType`, and `name` if not set or set to empty. Valid fields are: * clientData * groupType * memberCount * metadata * name (format: google-fieldmask)
  --update-group-fields: string # Optional. A field mask to restrict which fields on the group are updated. Multiple fields can be specified by separating them with commas. Defaults to `name` if not set or set to empty. Updated fields are replaced. Valid values are: * clientData * name (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/v1/{resourceName}"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: contactGroup, var: contact_group}, {name: readGroupFields, var: read_group_fields}, {name: updateGroupFields, var: update_group_fields}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, contact_group: $contact_group, read_group_fields: $read_group_fields, update_group_fields: $update_group_fields
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Provides a list of the authenticated user's contacts. Sync tokens expire 7 days after the full sync. A request with an expired sync token will get an error with an [google.rpc.ErrorInfo](https://cloud.google.com/apis/design/errors#error_info) with reason "EXPIRED_SYNC_TOKEN". In the case of such an error clients should make a full sync request without a `sync_token`. The first page of a full sync request has an additional quota. If the quota is exceeded, a 429 error will be returned. This quota is fixed and can not be increased. When the `sync_token` is specified, resources deleted since the last sync will be returned as a person with `PersonMetadata.deleted` set to true. When the `page_token` or `sync_token` is specified, all other request parameters must match the first call. Writes may have a propagation delay of several minutes for sync requests. Incremental syncs are not intended for read-after-write use cases. See example usage at [List the user's contacts that have changed](/people/v1/contacts#list_the_users_contacts_that_have_changed).
#
# GET /v1/{resourceName}/connections
# Returns: record<connections: table<addresses: list, ageRange: string, ageRanges: list, biographies: list, birthdays: list, braggingRights: list, calendarUrls: list, clientData: list, coverPhotos: list, emailAddresses: list, etag: string, events: list, externalIds: list, fileAses: list, genders: list, imClients: list, interests: list, locales: list, locations: list, memberships: list, metadata: record, miscKeywords: list, names: list, nicknames: list, occupations: list, organizations: list, phoneNumbers: list, photos: list, relations: list, relationshipInterests: list, relationshipStatuses: list, residences: list, resourceName: string, sipAddresses: list, skills: list, taglines: list, urls: list, userDefined: list>, nextPageToken: string, nextSyncToken: string, totalItems: int, totalPeople: int>
# operationId: people.people.connections.list
export def "people-people-connections-list" [
  resource_name: string
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
  --page-size: int # Optional. The number of connections to include in the response. Valid values are between 1 and 1000, inclusive. Defaults to 100 if not set or set to 0.
  --page-token: string # Optional. A page token, received from a previous response `next_page_token`. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `people.connections.list` must match the first call that provided the page token.
  --person-fields: string # Required. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --request-mask-include-field: string # Required. Comma-separated list of person fields to be included in the response. Each path should start with `person.`: for example, `person.names` or `person.photos`.
  --request-sync-token: oneof<nothing, bool> # Optional. Whether the response should return `next_sync_token` on the last page of results. It can be used to get incremental changes since the last request by setting it on the request `sync_token`. More details about sync behavior at `people.connections.list`.
  --sort-order: string@sort-order-completer # Optional. The order in which the connections should be sorted. Defaults to `LAST_MODIFIED_ASCENDING`.
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --sync-token: string # Optional. A sync token, received from a previous response `next_sync_token` Provide this to retrieve only the resources changed since the last request. When syncing, all other parameters provided to `people.connections.list` must match the first call that provided the sync token. More details about sync behavior at `people.connections.list`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v1/{resourceName}/connections"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: personFields, var: person_fields}, {name: "requestMask.includeField", var: request_mask_include_field}, {name: requestSyncToken, var: request_sync_token}, {name: sortOrder, var: sort_order}, {name: sources, var: sources, style: multi}, {name: syncToken, var: sync_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, person_fields: $person_fields, request_mask_include_field: $request_mask_include_field, request_sync_token: $request_sync_token, sort_order: $sort_order, sources: $sources, sync_token: $sync_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Modify the members of a contact group owned by the authenticated user. The only system contact groups that can have members added are `contactGroups/myContacts` and `contactGroups/starred`. Other system contact groups are deprecated and can only have contacts removed.
#
# POST /v1/{resourceName}/members:modify
# Returns: record<canNotRemoveLastContactGroupResourceNames: list<string>, notFoundResourceNames: list<string>>
# operationId: people.contactGroups.members.modify
export def "people-contact-groups-members-modify" [
  resource_name: string
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
  --resource-names-to-add: list<string> # Optional. The resource names of the contact people to add in the form of `people/{person_id}`. The total number of resource names in `resource_names_to_add` and `resource_names_to_remove` must be less than or equal to 1000.
  --resource-names-to-remove: list<string> # Optional. The resource names of the contact people to remove in the form of `people/{person_id}`. The total number of resource names in `resource_names_to_add` and `resource_names_to_remove` must be less than or equal to 1000.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resourceName}/members:modify"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: resourceNamesToAdd, var: resource_names_to_add}, {name: resourceNamesToRemove, var: resource_names_to_remove}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, resource_names_to_add: $resource_names_to_add, resource_names_to_remove: $resource_names_to_remove
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Copies an "Other contact" to a new contact in the user's "myContacts" group Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# POST /v1/{resourceName}:copyOtherContactToMyContactsGroup
# Returns: record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>
# operationId: people.otherContacts.copyOtherContactToMyContactsGroup
export def "people-other-contacts-copy-other-contact-to-my-contacts-group" [
  resource_name: string
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
  --copy-mask: string # Required. A field mask to restrict which fields are copied into the new contact. Valid values are: * emailAddresses * names * phoneNumbers (format: google-fieldmask)
  --read-mask: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to the copy mask with metadata and membership fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v1/{resourceName}:copyOtherContactToMyContactsGroup"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: copyMask, var: copy_mask}, {name: readMask, var: read_mask}, {name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, copy_mask: $copy_mask, read_mask: $read_mask, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact person. Any non-contact data will not be deleted. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# DELETE /v1/{resourceName}:deleteContact
# Returns: record
# operationId: people.people.deleteContact
export def "people-people-delete-contact" [
  resource_name: string
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
    path: "/v1/{resourceName}:deleteContact"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a contact's photo. Mutate requests for the same user should be done sequentially to avoid // lock contention.
#
# DELETE /v1/{resourceName}:deleteContactPhoto
# Returns: record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>>
# operationId: people.people.deleteContactPhoto
export def "people-people-delete-contact-photo" [
  resource_name: string
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
  --person-fields: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to empty if not set, which will skip the post mutate get. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: delete
    path: "/v1/{resourceName}:deleteContactPhoto"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: personFields, var: person_fields}, {name: sources, var: sources, style: multi}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update contact data for an existing contact person. Any non-contact data will not be modified. Any non-contact data in the person to update will be ignored. All fields specified in the `update_mask` will be replaced. The server returns a 400 error if `person.metadata.sources` is not specified for the contact to be updated or if there is no contact source. The server returns a 400 error with reason `"failedPrecondition"` if `person.metadata.sources.etag` is different than the contact's etag, which indicates the contact has changed since its data was read. Clients should get the latest person and merge their updates into the latest person. The server returns a 400 error if `memberships` are being updated and there are no contact group memberships specified on the person. The server returns a 400 error if more than one field is specified on a field that is a singleton for contact sources: * biographies * birthdays * genders * names Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PATCH /v1/{resourceName}:updateContact
# Returns: record<addresses: table<city: string, country: string, countryCode: string, extendedAddress: string, formattedType: string, formattedValue: string, metadata: record, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, ageRange: string, ageRanges: table<ageRange: string, metadata: record>, biographies: table<contentType: string, metadata: record, value: string>, birthdays: table<date: record, metadata: record, text: string>, braggingRights: table<metadata: record, value: string>, calendarUrls: table<formattedType: string, metadata: record, type: string, url: string>, clientData: table<key: string, metadata: record, value: string>, coverPhotos: table<metadata: record, url: string>, emailAddresses: table<displayName: string, formattedType: string, metadata: record, type: string, value: string>, etag: string, events: table<date: record, formattedType: string, metadata: record, type: string>, externalIds: table<formattedType: string, metadata: record, type: string, value: string>, fileAses: table<metadata: record, value: string>, genders: table<addressMeAs: string, formattedValue: string, metadata: record, value: string>, imClients: table<formattedProtocol: string, formattedType: string, metadata: record, protocol: string, type: string, username: string>, interests: table<metadata: record, value: string>, locales: table<metadata: record, value: string>, locations: table<buildingId: string, current: bool, deskCode: string, floor: string, floorSection: string, metadata: record, type: string, value: string>, memberships: table<contactGroupMembership: record, domainMembership: record, metadata: record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list<string>, objectType: string, previousResourceNames: list<string>, sources: list<record>>, miscKeywords: table<formattedType: string, metadata: record, type: string, value: string>, names: table<displayName: string, displayNameLastFirst: string, familyName: string, givenName: string, honorificPrefix: string, honorificSuffix: string, metadata: record, middleName: string, phoneticFamilyName: string, phoneticFullName: string, phoneticGivenName: string, phoneticHonorificPrefix: string, phoneticHonorificSuffix: string, phoneticMiddleName: string, unstructuredName: string>, nicknames: table<metadata: record, type: string, value: string>, occupations: table<metadata: record, value: string>, organizations: table<costCenter: string, current: bool, department: string, domain: string, endDate: record, formattedType: string, fullTimeEquivalentMillipercent: int, jobDescription: string, location: string, metadata: record, name: string, phoneticName: string, startDate: record, symbol: string, title: string, type: string>, phoneNumbers: table<canonicalForm: string, formattedType: string, metadata: record, type: string, value: string>, photos: table<metadata: record, url: string>, relations: table<formattedType: string, metadata: record, person: string, type: string>, relationshipInterests: table<formattedValue: string, metadata: record, value: string>, relationshipStatuses: table<formattedValue: string, metadata: record, value: string>, residences: table<current: bool, metadata: record, value: string>, resourceName: string, sipAddresses: table<formattedType: string, metadata: record, type: string, value: string>, skills: table<metadata: record, value: string>, taglines: table<metadata: record, value: string>, urls: table<formattedType: string, metadata: record, type: string, value: string>, userDefined: table<key: string, metadata: record, value: string>>
# operationId: people.people.updateContact
export def "people-people-update-contact" [
  resource_name: string
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
  --person-fields: string # Optional. A field mask to restrict which fields on each person are returned. Multiple fields can be specified by separating them with commas. Defaults to all fields if not set. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
  --update-person-fields: string # Required. A field mask to restrict which fields on the person are updated. Multiple fields can be specified by separating them with commas. All updated fields will be replaced. Valid values are: * addresses * biographies * birthdays * calendarUrls * clientData * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * relations * sipAddresses * urls * userDefined
  --addresses: list # The person's street addresses. — item shape: {city?: string, country?: string, countryCode?: string, extendedAddress?: string, formattedValue?: string, metadata?: record, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --biographies: list # The person's biographies. This field is a singleton for contact sources. — item shape: {contentType?: "CONTENT_TYPE_UNSPECIFIED"|"TEXT_PLAIN"|"TEXT_HTML", metadata?: record, value?: string}
  --birthdays: list # The person's birthdays. This field is a singleton for contact sources. — item shape: {date?: record, metadata?: record, text?: string}
  --bragging-rights: list # **DEPRECATED**: No data will be returned The person's bragging rights. — item shape: {metadata?: record, value?: string}
  --calendar-urls: list # The person's calendar URLs. — item shape: {metadata?: record, type?: string, url?: string}
  --client-data: list # The person's client data. — item shape: {key?: string, metadata?: record, value?: string}
  --email-addresses: list # The person's email addresses. For `people.connections.list` and `otherContacts.list` the number of email addresses is limited to 100. If a Person has more email addresses the entire set can be obtained by calling GetPeople. — item shape: {displayName?: string, metadata?: record, type?: string, value?: string}
  --etag: string # The [HTTP entity tag](https://en.wikipedia.org/wiki/HTTP_ETag) of the resource. Used for web cache validation.
  --events: list # The person's events. — item shape: {date?: record, metadata?: record, type?: string}
  --external-ids: list # The person's external IDs. — item shape: {metadata?: record, type?: string, value?: string}
  --file-ases: list # The person's file-ases. — item shape: {metadata?: record, value?: string}
  --genders: list # The person's genders. This field is a singleton for contact sources. — item shape: {addressMeAs?: string, metadata?: record, value?: string}
  --im-clients: list # The person's instant messaging clients. — item shape: {metadata?: record, protocol?: string, type?: string, username?: string}
  --interests: list # The person's interests. — item shape: {metadata?: record, value?: string}
  --locales: list # The person's locale preferences. — item shape: {metadata?: record, value?: string}
  --locations: list # The person's locations. — item shape: {buildingId?: string, current?: bool, deskCode?: string, floor?: string, floorSection?: string, metadata?: record, type?: string, value?: string}
  --memberships: list # The person's group memberships. — item shape: {contactGroupMembership?: record, domainMembership?: record, metadata?: record}
  --metadata: record # The metadata about a person. — shape: {sources?: list}
  --misc-keywords: list # The person's miscellaneous keywords. — item shape: {metadata?: record, type?: "TYPE_UNSPECIFIED"|"OUTLOOK_BILLING_INFORMATION"|"OUTLOOK_DIRECTORY_SERVER"|"OUTLOOK_KEYWORD"|"OUTLOOK_MILEAGE"|"OUTLOOK_PRIORITY"|"OUTLOOK_SENSITIVITY"|"OUTLOOK_SUBJECT"|"OUTLOOK_USER"|"HOME"|"WORK"|"OTHER", value?: string}
  --names: list # The person's names. This field is a singleton for contact sources. — item shape: {familyName?: string, givenName?: string, honorificPrefix?: string, honorificSuffix?: string, metadata?: record, middleName?: string, phoneticFamilyName?: string, phoneticFullName?: string, phoneticGivenName?: string, phoneticHonorificPrefix?: string, phoneticHonorificSuffix?: string, phoneticMiddleName?: string, unstructuredName?: string}
  --nicknames: list # The person's nicknames. — item shape: {metadata?: record, type?: "DEFAULT"|"MAIDEN_NAME"|"INITIALS"|"GPLUS"|"OTHER_NAME"|"ALTERNATE_NAME"|"SHORT_NAME", value?: string}
  --occupations: list # The person's occupations. — item shape: {metadata?: record, value?: string}
  --organizations: list # The person's past or current organizations. — item shape: {costCenter?: string, current?: bool, department?: string, domain?: string, endDate?: record, fullTimeEquivalentMillipercent?: int, jobDescription?: string, location?: string, metadata?: record, name?: string, phoneticName?: string, startDate?: record, symbol?: string, title?: string, type?: string}
  --phone-numbers: list # The person's phone numbers. For `people.connections.list` and `otherContacts.list` the number of phone numbers is limited to 100. If a Person has more phone numbers the entire set can be obtained by calling GetPeople. — item shape: {metadata?: record, type?: string, value?: string}
  --relations: list # The person's relations. — item shape: {metadata?: record, person?: string, type?: string}
  --residences: list # **DEPRECATED**: (Please use `person.locations` instead) The person's residences. — item shape: {current?: bool, metadata?: record, value?: string}
  --body-resource-name: string # The resource name for the person, assigned by the server. An ASCII string in the form of `people/{person_id}`. (spec name: resourceName)
  --sip-addresses: list # The person's SIP addresses. — item shape: {metadata?: record, type?: string, value?: string}
  --skills: list # The person's skills. — item shape: {metadata?: record, value?: string}
  --urls: list # The person's associated URLs. — item shape: {metadata?: record, type?: string, value?: string}
  --user-defined: list # The person's user defined data. — item shape: {key?: string, metadata?: record, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{resourceName}:updateContact"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: personFields, var: person_fields}, {name: sources, var: sources, style: multi}, {name: updatePersonFields, var: update_person_fields}]
    body: {content_type: "application/json", kind: json, fields: [{name: addresses, var: addresses}, {name: biographies, var: biographies}, {name: birthdays, var: birthdays}, {name: braggingRights, var: bragging_rights}, {name: calendarUrls, var: calendar_urls}, {name: clientData, var: client_data}, {name: emailAddresses, var: email_addresses}, {name: etag, var: etag}, {name: events, var: events}, {name: externalIds, var: external_ids}, {name: fileAses, var: file_ases}, {name: genders, var: genders}, {name: imClients, var: im_clients}, {name: interests, var: interests}, {name: locales, var: locales}, {name: locations, var: locations}, {name: memberships, var: memberships}, {name: metadata, var: metadata}, {name: miscKeywords, var: misc_keywords}, {name: names, var: names}, {name: nicknames, var: nicknames}, {name: occupations, var: occupations}, {name: organizations, var: organizations}, {name: phoneNumbers, var: phone_numbers}, {name: relations, var: relations}, {name: residences, var: residences}, {name: resourceName, var: body_resource_name}, {name: sipAddresses, var: sip_addresses}, {name: skills, var: skills}, {name: urls, var: urls}, {name: userDefined, var: user_defined}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, sources: $sources, update_person_fields: $update_person_fields, addresses: $addresses, biographies: $biographies, birthdays: $birthdays, bragging_rights: $bragging_rights, calendar_urls: $calendar_urls, client_data: $client_data, email_addresses: $email_addresses, etag: $etag, events: $events, external_ids: $external_ids, file_ases: $file_ases, genders: $genders, im_clients: $im_clients, interests: $interests, locales: $locales, locations: $locations, memberships: $memberships, metadata: $metadata, misc_keywords: $misc_keywords, names: $names, nicknames: $nicknames, occupations: $occupations, organizations: $organizations, phone_numbers: $phone_numbers, relations: $relations, residences: $residences, body_resource_name: $body_resource_name, sip_addresses: $sip_addresses, skills: $skills, urls: $urls, user_defined: $user_defined
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a contact's photo. Mutate requests for the same user should be sent sequentially to avoid increased latency and failures.
#
# PATCH /v1/{resourceName}:updateContactPhoto
# Returns: record<person: record<addresses: list<record>, ageRange: string, ageRanges: list<record>, biographies: list<record>, birthdays: list<record>, braggingRights: list<record>, calendarUrls: list<record>, clientData: list<record>, coverPhotos: list<record>, emailAddresses: list<record>, etag: string, events: list<record>, externalIds: list<record>, fileAses: list<record>, genders: list<record>, imClients: list<record>, interests: list<record>, locales: list<record>, locations: list<record>, memberships: list<record>, metadata: record<deleted: bool, linkedPeopleResourceNames: list, objectType: string, previousResourceNames: list, sources: list>, miscKeywords: list<record>, names: list<record>, nicknames: list<record>, occupations: list<record>, organizations: list<record>, phoneNumbers: list<record>, photos: list<record>, relations: list<record>, relationshipInterests: list<record>, relationshipStatuses: list<record>, residences: list<record>, resourceName: string, sipAddresses: list<record>, skills: list<record>, taglines: list<record>, urls: list<record>, userDefined: list<record>>>
# operationId: people.people.updateContactPhoto
export def "people-people-update-contact-photo" [
  resource_name: string
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
  --person-fields: string # Optional. A field mask to restrict which fields on the person are returned. Multiple fields can be specified by separating them with commas. Defaults to empty if not set, which will skip the post mutate get. Valid values are: * addresses * ageRanges * biographies * birthdays * calendarUrls * clientData * coverPhotos * emailAddresses * events * externalIds * genders * imClients * interests * locales * locations * memberships * metadata * miscKeywords * names * nicknames * occupations * organizations * phoneNumbers * photos * relations * sipAddresses * skills * urls * userDefined (format: google-fieldmask)
  --photo-bytes: string # Required. Raw photo bytes (format: byte)
  --sources: list<string> # Optional. A mask of what source types to return. Defaults to READ_SOURCE_TYPE_CONTACT and READ_SOURCE_TYPE_PROFILE if not set.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v1/{resourceName}:updateContactPhoto"
    path_params: [{name: resourceName, var: resource_name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: personFields, var: person_fields}, {name: photoBytes, var: photo_bytes}, {name: sources, var: sources}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    resource_name: $resource_name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, person_fields: $person_fields, photo_bytes: $photo_bytes, sources: $sources
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
