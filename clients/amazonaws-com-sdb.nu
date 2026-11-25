# Auto-generated client for Amazon SimpleDB v2009-04-15
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sdb/2009-04-15/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLEDB_TOKEN

const CLIENT = {
  base_url: "http://sdb.amazonaws.com"
  token_env_var: "AMAZON_SIMPLEDB_TOKEN"
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

def base-url-completer [] { ["http://sdb.amazonaws.com" "https://sdb.amazonaws.com" "http://sdb.us-east-2.amazonaws.com" "http://sdb.us-west-1.amazonaws.com" "http://sdb.us-west-2.amazonaws.com" "http://sdb.us-gov-west-1.amazonaws.com" "http://sdb.us-gov-east-1.amazonaws.com" "http://sdb.ca-central-1.amazonaws.com" "http://sdb.eu-north-1.amazonaws.com" "http://sdb.eu-west-1.amazonaws.com" "http://sdb.eu-west-2.amazonaws.com" "http://sdb.eu-west-3.amazonaws.com" "http://sdb.eu-central-1.amazonaws.com" "http://sdb.eu-south-1.amazonaws.com" "http://sdb.af-south-1.amazonaws.com" "http://sdb.ap-northeast-1.amazonaws.com" "http://sdb.ap-northeast-2.amazonaws.com" "http://sdb.ap-northeast-3.amazonaws.com" "http://sdb.ap-southeast-1.amazonaws.com" "http://sdb.ap-southeast-2.amazonaws.com" "http://sdb.ap-east-1.amazonaws.com" "http://sdb.ap-south-1.amazonaws.com" "http://sdb.sa-east-1.amazonaws.com" "http://sdb.me-south-1.amazonaws.com" "https://sdb.us-east-2.amazonaws.com" "https://sdb.us-west-1.amazonaws.com" "https://sdb.us-west-2.amazonaws.com" "https://sdb.us-gov-west-1.amazonaws.com" "https://sdb.us-gov-east-1.amazonaws.com" "https://sdb.ca-central-1.amazonaws.com" "https://sdb.eu-north-1.amazonaws.com" "https://sdb.eu-west-1.amazonaws.com" "https://sdb.eu-west-2.amazonaws.com" "https://sdb.eu-west-3.amazonaws.com" "https://sdb.eu-central-1.amazonaws.com" "https://sdb.eu-south-1.amazonaws.com" "https://sdb.af-south-1.amazonaws.com" "https://sdb.ap-northeast-1.amazonaws.com" "https://sdb.ap-northeast-2.amazonaws.com" "https://sdb.ap-northeast-3.amazonaws.com" "https://sdb.ap-southeast-1.amazonaws.com" "https://sdb.ap-southeast-2.amazonaws.com" "https://sdb.ap-east-1.amazonaws.com" "https://sdb.ap-south-1.amazonaws.com" "https://sdb.sa-east-1.amazonaws.com" "https://sdb.me-south-1.amazonaws.com" "http://sdb.cn-north-1.amazonaws.com.cn" "http://sdb.cn-northwest-1.amazonaws.com.cn" "https://sdb.cn-north-1.amazonaws.com.cn" "https://sdb.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["BatchDeleteAttributes"] }
def version-completer [] { ["2009-04-15"] }
def action-completer-1 [] { ["BatchPutAttributes"] }
def action-completer-2 [] { ["CreateDomain"] }
def action-completer-3 [] { ["DeleteAttributes"] }
def action-completer-4 [] { ["DeleteDomain"] }
def action-completer-5 [] { ["DomainMetadata"] }
def action-completer-6 [] { ["GetAttributes"] }
def action-completer-7 [] { ["ListDomains"] }
def action-completer-8 [] { ["PutAttributes"] }
def action-completer-9 [] { ["Select"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {}
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-batch-delete-attributes" "post-batch-delete-attributes" "get-batch-put-attributes" "post-batch-put-attributes" "get-create-domain" "post-create-domain" "get-delete-attributes" "post-delete-attributes" "get-delete-domain" "post-delete-domain" "get-domain-metadata" "post-domain-metadata" "get-get-attributes" "post-get-attributes" "get-list-domains" "post-list-domains" "get-put-attributes" "post-put-attributes" "get-select" "post-select" "commands"] | sort) } | get name | first)
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

# Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. The following limitations are enforced for this operation: 1 MB request size 25 item limit per BatchDeleteAttributes operation
#
# GET /
# operationId: GET_BatchDeleteAttributes
export def "get-batch-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain in which the attributes are being deleted. (required)
  --items: list # A list of items on which to perform the operation. (required)
  --action: string@action-completer # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: Items, var: items, style: multi, required: true}, {name: Action, var: action, required: true, default: BatchDeleteAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, items: $items, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Performs multiple DeleteAttributes operations in a single call, which reduces round trips and latencies. This enables Amazon SimpleDB to optimize requests, which generally yields better throughput. If you specify BatchDeleteAttributes without attributes or values, all the attributes for the item are deleted. BatchDeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute doesn't result in an error. The BatchDeleteAttributes operation succeeds or fails in its entirety. There are no partial deletes. You can execute multiple BatchDeleteAttributes operations and other operations in parallel. However, large numbers of concurrent BatchDeleteAttributes calls can result in Service Unavailable (503) responses. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. The following limitations are enforced for this operation: 1 MB request size 25 item limit per BatchDeleteAttributes operation
#
# POST /
# operationId: POST_BatchDeleteAttributes
export def "post-batch-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: BatchDeleteAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The BatchPutAttributes operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple PutAttribute operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. The client may specify the item name with the Item.X.ItemName parameter. The client may specify new attributes using a combination of the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value parameters. The client may specify the first attribute for the first item using the parameters Item.0.Attribute.0.Name and Item.0.Attribute.0.Value, and for the second attribute for the first item by the parameters Item.0.Attribute.1.Name and Item.0.Attribute.1.Value, and so on. Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", "second_value" }. However, it cannot have two attribute instances where both the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value are the same. Optionally, the requester can supply the Replace parameter for each individual value. Setting this value to true will cause the new attribute values to replace the existing attribute values. For example, if an item I has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requester does a BatchPutAttributes of {'I', 'b', '4' } with the Replace parameter set to true, the final attributes of the item will be { 'a', '1' } and { 'b', '4' }, replacing the previous values of the 'b' attribute with the new value. You cannot specify an empty string as an item or as an attribute name. The BatchPutAttributes operation succeeds or fails in its entirety. There are no partial puts. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. You can execute multiple BatchPutAttributes operations and other operations in parallel. However, large numbers of concurrent BatchPutAttributes calls can result in Service Unavailable (503) responses. The following limitations are enforced for this operation: 256 attribute name-value pairs per item 1 MB request size 1 billion attributes per domain 10 GB of total user data storage per domain 25 item limit per BatchPutAttributes operation
#
# GET /
# operationId: GET_BatchPutAttributes
export def "get-batch-put-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain in which the attributes are being stored. (required)
  --items: list # A list of items on which to perform the operation. (required)
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: Items, var: items, style: multi, required: true}, {name: Action, var: action, required: true, default: BatchPutAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, items: $items, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The BatchPutAttributes operation creates or replaces attributes within one or more items. By using this operation, the client can perform multiple PutAttribute operation with a single call. This helps yield savings in round trips and latencies, enabling Amazon SimpleDB to optimize requests and generally produce better throughput. The client may specify the item name with the Item.X.ItemName parameter. The client may specify new attributes using a combination of the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value parameters. The client may specify the first attribute for the first item using the parameters Item.0.Attribute.0.Name and Item.0.Attribute.0.Value, and for the second attribute for the first item by the parameters Item.0.Attribute.1.Name and Item.0.Attribute.1.Value, and so on. Attributes are uniquely identified within an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", "second_value" }. However, it cannot have two attribute instances where both the Item.X.Attribute.Y.Name and Item.X.Attribute.Y.Value are the same. Optionally, the requester can supply the Replace parameter for each individual value. Setting this value to true will cause the new attribute values to replace the existing attribute values. For example, if an item I has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requester does a BatchPutAttributes of {'I', 'b', '4' } with the Replace parameter set to true, the final attributes of the item will be { 'a', '1' } and { 'b', '4' }, replacing the previous values of the 'b' attribute with the new value. You cannot specify an empty string as an item or as an attribute name. The BatchPutAttributes operation succeeds or fails in its entirety. There are no partial puts. This operation is vulnerable to exceeding the maximum URL size when making a REST request using the HTTP GET method. This operation does not support conditions using Expected.X.Name, Expected.X.Value, or Expected.X.Exists. You can execute multiple BatchPutAttributes operations and other operations in parallel. However, large numbers of concurrent BatchPutAttributes calls can result in Service Unavailable (503) responses. The following limitations are enforced for this operation: 256 attribute name-value pairs per item 1 MB request size 1 billion attributes per domain 10 GB of total user data storage per domain 25 item limit per BatchPutAttributes operation
#
# POST /
# operationId: POST_BatchPutAttributes
export def "post-batch-put-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: BatchPutAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateDomain operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The CreateDomain operation may take 10 or more seconds to complete. CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. The client can create up to 100 domains per account. If the client requires additional domains, go to http://aws.amazon.com/contact-us/simpledb-limit-request/ (http://aws.amazon.com/contact-us/simpledb-limit-request/).
#
# GET /
# operationId: GET_CreateDomain
export def "get-create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain to create. The name can range between 3 and 255 characters and can contain the following characters: a-z, A-Z, 0-9, '_', '-', and '.'. (required)
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: Action, var: action, required: true, default: CreateDomain}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The CreateDomain operation creates a new domain. The domain name should be unique among the domains associated with the Access Key ID provided in the request. The CreateDomain operation may take 10 or more seconds to complete. CreateDomain is an idempotent operation; running it multiple times using the same domain name will not result in an error response. The client can create up to 100 domains per account. If the client requires additional domains, go to http://aws.amazon.com/contact-us/simpledb-limit-request/ (http://aws.amazon.com/contact-us/simpledb-limit-request/).
#
# POST /
# operationId: POST_CreateDomain
export def "post-create-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: CreateDomain}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. If DeleteAttributes is called without being passed any attributes or values specified, all the attributes for the item are deleted. DeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a GetAttributes or Select operation (read) immediately after a DeleteAttributes or PutAttributes operation (write) might not return updated item data.
#
# GET /
# operationId: GET_DeleteAttributes
export def "get-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain in which to perform the operation. (required)
  --item-name: string # The name of the item. Similar to rows on a spreadsheet, items represent individual objects that contain one or more value-attribute pairs. (required)
  --attributes: list # A list of Attributes. Similar to columns on a spreadsheet, attributes represent categories of data that can be assigned to items.
  --expected: record # The update condition which, if specified, determines whether the specified attributes will be deleted or not. The update condition must be satisfied in order for this request to be processed and the attributes to be deleted.
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: ItemName, var: item_name, required: true}, {name: Attributes, var: attributes, style: multi}, {name: Expected, var: expected, style: multi}, {name: Action, var: action, required: true, default: DeleteAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, item_name: $item_name, attributes: $attributes, expected: $expected, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes one or more attributes associated with an item. If all attributes of the item are deleted, the item is deleted. If DeleteAttributes is called without being passed any attributes or values specified, all the attributes for the item are deleted. DeleteAttributes is an idempotent operation; running it multiple times on the same item or attribute does not result in an error response. Because Amazon SimpleDB makes multiple copies of item data and uses an eventual consistency update model, performing a GetAttributes or Select operation (read) immediately after a DeleteAttributes or PutAttributes operation (write) might not return updated item data.
#
# POST /
# operationId: POST_DeleteAttributes
export def "post-delete-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: DeleteAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeleteDomain operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The DeleteDomain operation might take 10 or more seconds to complete. Running DeleteDomain on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response.
#
# GET /
# operationId: GET_DeleteDomain
export def "get-delete-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain to delete. (required)
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: Action, var: action, required: true, default: DeleteDomain}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The DeleteDomain operation deletes a domain. Any items (and their attributes) in the domain are deleted as well. The DeleteDomain operation might take 10 or more seconds to complete. Running DeleteDomain on a domain that does not exist or running the function multiple times using the same domain name will not result in an error response.
#
# POST /
# operationId: POST_DeleteDomain
export def "post-delete-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: DeleteDomain}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values.
#
# GET /
# operationId: GET_DomainMetadata
export def "get-domain-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain for which to display the metadata of. (required)
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: Action, var: action, required: true, default: DomainMetadata}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns information about the domain, including when the domain was created, the number of items and attributes in the domain, and the size of the attribute names and values.
#
# POST /
# operationId: POST_DomainMetadata
export def "post-domain-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: DomainMetadata}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned.
#
# GET /
# operationId: GET_GetAttributes
export def "get-get-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain in which to perform the operation. (required)
  --item-name: string # The name of the item. (required)
  --attribute-names: list<string> # The names of the attributes.
  --consistent-read: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If true, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: ItemName, var: item_name, required: true}, {name: AttributeNames, var: attribute_names, style: multi}, {name: ConsistentRead, var: consistent_read}, {name: Action, var: action, required: true, default: GetAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, item_name: $item_name, attribute_names: $attribute_names, consistent_read: $consistent_read, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns all of the attributes associated with the specified item. Optionally, the attributes returned can be limited to one or more attributes by specifying an attribute name parameter. If the item does not exist on the replica that was accessed for this operation, an empty set is returned. The system does not return an error as it cannot guarantee the item does not exist on other replicas. If GetAttributes is called without being passed any attribute names, all the attributes for the item are returned.
#
# POST /
# operationId: POST_GetAttributes
export def "post-get-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: GetAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListDomains operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by MaxNumberOfDomains (#MaxNumberOfDomains). A NextToken (#NextToken) is returned if there are more than MaxNumberOfDomains domains. Calling ListDomains successive times with the NextToken provided by the operation returns up to MaxNumberOfDomains more domain names with each successive operation call.
#
# GET /
# operationId: GET_ListDomains
export def "get-list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --max-number-of-domains: int # The maximum number of domain names you want returned. The range is 1 to 100. The default setting is 100.
  --next-token: string # A string informing Amazon SimpleDB where to start the next list of domain names.
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: MaxNumberOfDomains, var: max_number_of_domains}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: ListDomains}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, max_number_of_domains: $max_number_of_domains, next_token: $next_token, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The ListDomains operation lists all domains associated with the Access Key ID. It returns domain names up to the limit set by MaxNumberOfDomains (#MaxNumberOfDomains). A NextToken (#NextToken) is returned if there are more than MaxNumberOfDomains domains. Calling ListDomains successive times with the NextToken provided by the operation returns up to MaxNumberOfDomains more domain names with each successive operation call.
#
# POST /
# operationId: POST_ListDomains
export def "post-list-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --max-number-of-domains: string # Pagination limit
  --next-token: string # Pagination token
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: MaxNumberOfDomains, var: max_number_of_domains}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: ListDomains}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, max_number_of_domains: $max_number_of_domains, next_token: $next_token, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the Attribute.X.Name and Attribute.X.Value parameters. The client specifies the first attribute by the parameters Attribute.0.Name and Attribute.0.Value, the second attribute by the parameters Attribute.1.Name and Attribute.1.Value, and so on. Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", second_value" }. However, it cannot have two attribute instances where both the Attribute.X.Name and Attribute.X.Value are the same. Optionally, the requestor can supply the Replace parameter for each individual attribute. Setting this value to true causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requestor calls PutAttributes using the attributes { 'b', '4' } with the Replace parameter set to true, the final attributes of the item are changed to { 'a', '1' } and { 'b', '4' }, which replaces the previous values of the 'b' attribute with the new value. Using PutAttributes to replace attribute values that do not exist will not result in an error response. You cannot specify an empty string as an attribute name. Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate GetAttributes or Select operation (read) immediately after a PutAttributes or DeleteAttributes operation (write) might not return the updated data. The following limitations are enforced for this operation: 256 total attribute name-value pairs per item One billion attributes per domain 10 GB of total user data storage per domain
#
# GET /
# operationId: GET_PutAttributes
export def "get-put-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --domain-name: string # The name of the domain in which to perform the operation. (required)
  --item-name: string # The name of the item. (required)
  --attributes: list # The list of attributes. (required)
  --expected: record # The update condition which, if specified, determines whether the specified attributes will be updated or not. The update condition must be satisfied in order for this request to be processed and the attributes to be updated.
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: DomainName, var: domain_name, required: true}, {name: ItemName, var: item_name, required: true}, {name: Attributes, var: attributes, style: multi, required: true}, {name: Expected, var: expected, style: multi}, {name: Action, var: action, required: true, default: PutAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, domain_name: $domain_name, item_name: $item_name, attributes: $attributes, expected: $expected, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The PutAttributes operation creates or replaces attributes in an item. The client may specify new attributes using a combination of the Attribute.X.Name and Attribute.X.Value parameters. The client specifies the first attribute by the parameters Attribute.0.Name and Attribute.0.Value, the second attribute by the parameters Attribute.1.Name and Attribute.1.Value, and so on. Attributes are uniquely identified in an item by their name/value combination. For example, a single item can have the attributes { "first_name", "first_value" } and { "first_name", second_value" }. However, it cannot have two attribute instances where both the Attribute.X.Name and Attribute.X.Value are the same. Optionally, the requestor can supply the Replace parameter for each individual attribute. Setting this value to true causes the new attribute value to replace the existing attribute value(s). For example, if an item has the attributes { 'a', '1' }, { 'b', '2'} and { 'b', '3' } and the requestor calls PutAttributes using the attributes { 'b', '4' } with the Replace parameter set to true, the final attributes of the item are changed to { 'a', '1' } and { 'b', '4' }, which replaces the previous values of the 'b' attribute with the new value. Using PutAttributes to replace attribute values that do not exist will not result in an error response. You cannot specify an empty string as an attribute name. Because Amazon SimpleDB makes multiple copies of client data and uses an eventual consistency update model, an immediate GetAttributes or Select operation (read) immediately after a PutAttributes or DeleteAttributes operation (write) might not return the updated data. The following limitations are enforced for this operation: 256 total attribute name-value pairs per item One billion attributes per domain 10 GB of total user data storage per domain
#
# POST /
# operationId: POST_PutAttributes
export def "post-put-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: Action, var: action, required: true, default: PutAttributes}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Select operation returns a set of attributes for ItemNames that match the select expression. Select is similar to the standard SQL SELECT statement. The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate NextToken so the client can access the next page of results. For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide.
#
# GET /
# operationId: GET_Select
export def "get-select" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --select-expression: string # The expression used to query the domain. (required)
  --next-token: string # A string informing Amazon SimpleDB where to start the next list of ItemNames.
  --consistent-read: oneof<nothing, bool> # Determines whether or not strong consistency should be enforced when data is read from SimpleDB. If true, any data previously written to SimpleDB will be returned. Otherwise, results will be consistent eventually, and the client may not see data that was written immediately before your read.
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
]: nothing -> any {
  http-request {
    method: get
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: SelectExpression, var: select_expression, required: true}, {name: NextToken, var: next_token}, {name: ConsistentRead, var: consistent_read}, {name: Action, var: action, required: true, default: Select}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, select_expression: $select_expression, next_token: $next_token, consistent_read: $consistent_read, action: $action, version: $version
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# The Select operation returns a set of attributes for ItemNames that match the select expression. Select is similar to the standard SQL SELECT statement. The total size of the response cannot exceed 1 MB in total size. Amazon SimpleDB automatically adjusts the number of items returned per page to enforce this limit. For example, if the client asks to retrieve 2500 items, but each individual item is 10 kB in size, the system returns 100 items and an appropriate NextToken so the client can access the next page of results. For information on how to construct select expressions, see Using Select to Create Amazon SimpleDB Queries in the Developer Guide.
#
# POST /
# operationId: POST_Select
export def "post-select" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-access-key-id: string # required
  --signature-method: string # required
  --signature-version: string # required
  --timestamp: string # required
  --signature: string # required
  --next-token: string # Pagination token
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --body: any
]: any -> any {
  $in | http-request {
    method: post
    path: "/"
    query: [{name: AWSAccessKeyId, var: aws_access_key_id, required: true}, {name: SignatureMethod, var: signature_method, required: true}, {name: SignatureVersion, var: signature_version, required: true}, {name: Timestamp, var: timestamp, required: true}, {name: Signature, var: signature, required: true}, {name: NextToken, var: next_token}, {name: Action, var: action, required: true, default: Select}, {name: Version, var: version, required: true, default: "2009-04-15"}]
    body: {content_type: "text/xml", kind: opaque, accepts: scalar}
    accept: ["text/xml"]
    ok: [200]
    auth: bearer
  } {
    aws_access_key_id: $aws_access_key_id, signature_method: $signature_method, signature_version: $signature_version, timestamp: $timestamp, signature: $signature, next_token: $next_token, action: $action, version: $version, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
