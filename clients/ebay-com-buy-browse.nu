# Auto-generated client for Browse API v1.1.0
# Source: https://api.apis.guru/v2/specs/ebay.com/buy-browse/v1.1.0/swagger.json
# Auth: --token flag or $env.BROWSE_API_TOKEN

const CLIENT = {
  base_url: "https://api.ebay.com/buy/browse/v1"
  token_env_var: "BROWSE_API_TOKEN"
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

def base-url-completer [] { ["https://api.ebay.com/buy/browse/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-items: "record<items: table<additionalImages: list, adultOnly: bool, ageGroup: string, availableCoupons: list, bidCount: int, brand: string, buyingOptions: list, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: list, gender: string, gtin: string, image: record, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, localizedAspects: list, lotSize: int, marketingPrice: record, material: string, minimumPriceToBid: record, mpn: string, pattern: string, paymentMethods: list, price: record, priceDisplayCondition: string, primaryItemGroup: record, primaryProductReviewRating: record, product: record, productFicheWebUrl: string, qualifiedPrograms: list, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record, seller: record, sellerItemRevision: string, shipToLocations: record, shippingOptions: list, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: list, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record, unitPricingMeasure: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-item-by-legacy-id: "record<additionalImages: table<height: int, imageUrl: string, width: int>, adultOnly: bool, ageGroup: string, availableCoupons: table<constraint: string, discountAmount: record, discountType: string, message: string, redemptionCode: string, termsWebUrl: string>, bidCount: int, brand: string, buyingOptions: list<string>, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: table<availabilityThreshold: int, availabilityThresholdType: string, deliveryOptions: list, estimatedAvailabilityStatus: string, estimatedAvailableQuantity: int, estimatedSoldQuantity: int>, gender: string, gtin: string, image: record<height: int, imageUrl: string, width: int>, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, postalCode: string, stateOrProvince: string>, itemWebUrl: string, legacyItemId: string, localizedAspects: table<name: string, type: string, value: string>, lotSize: int, marketingPrice: record<discountAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, discountPercentage: string, originalPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceTreatment: string>, material: string, minimumPriceToBid: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, mpn: string, pattern: string, paymentMethods: table<paymentInstructions: list, paymentMethodBrands: list, paymentMethodType: string, sellerInstructions: list>, price: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDisplayCondition: string, primaryItemGroup: record<itemGroupAdditionalImages: list<record>, itemGroupHref: string, itemGroupId: string, itemGroupImage: record<height: int, imageUrl: string, width: int>, itemGroupTitle: string, itemGroupType: string>, primaryProductReviewRating: record<averageRating: string, ratingHistograms: list<record>, reviewCount: int>, product: record<additionalImages: list<record>, additionalProductIdentities: list<record>, aspectGroups: list<record>, brand: string, description: string, gtins: list<string>, image: record<height: int, imageUrl: string, width: int>, mpns: list<string>, title: string>, productFicheWebUrl: string, qualifiedPrograms: list<string>, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record<extendedHolidayReturnsOffered: bool, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, seller: record<feedbackPercentage: string, feedbackScore: int, sellerAccountType: string, sellerLegalInfo: record<email: string, fax: string, imprint: string, legalContactFirstName: string, legalContactLastName: string, name: string, phone: string, registrationNumber: string, sellerProvidedLegalAddress: record, termsOfService: string, vatDetails: list>, username: string>, sellerItemRevision: string, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<additionalShippingCostPerUnit: record, cutOffDateUsedForEstimate: string, fulfilledThrough: string, guaranteedDelivery: bool, importCharges: record, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, quantityUsedForEstimate: int, shipToLocationUsedForEstimate: record, shippingCarrierCode: string, shippingCost: record, shippingCostType: string, shippingServiceCode: string, trademarkSymbol: string, type: string>, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: table<ebayCollectAndRemitTax: bool, includedInPrice: bool, shippingAndHandlingTaxed: bool, taxJurisdiction: record, taxPercentage: string, taxType: string>, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, unitPricingMeasure: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-items-by-item-group: "record<commonDescriptions: table<description: string, itemIds: list>, items: table<additionalImages: list, adultOnly: bool, ageGroup: string, availableCoupons: list, bidCount: int, brand: string, buyingOptions: list, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: list, gender: string, gtin: string, image: record, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, localizedAspects: list, lotSize: int, marketingPrice: record, material: string, minimumPriceToBid: record, mpn: string, pattern: string, paymentMethods: list, price: record, priceDisplayCondition: string, primaryItemGroup: record, primaryProductReviewRating: record, product: record, productFicheWebUrl: string, qualifiedPrograms: list, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record, seller: record, sellerItemRevision: string, shipToLocations: record, shippingOptions: list, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: list, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record, unitPricingMeasure: string, warnings: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-item: "record<additionalImages: table<height: int, imageUrl: string, width: int>, adultOnly: bool, ageGroup: string, availableCoupons: table<constraint: string, discountAmount: record, discountType: string, message: string, redemptionCode: string, termsWebUrl: string>, bidCount: int, brand: string, buyingOptions: list<string>, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: table<availabilityThreshold: int, availabilityThresholdType: string, deliveryOptions: list, estimatedAvailabilityStatus: string, estimatedAvailableQuantity: int, estimatedSoldQuantity: int>, gender: string, gtin: string, image: record<height: int, imageUrl: string, width: int>, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, postalCode: string, stateOrProvince: string>, itemWebUrl: string, legacyItemId: string, localizedAspects: table<name: string, type: string, value: string>, lotSize: int, marketingPrice: record<discountAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, discountPercentage: string, originalPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceTreatment: string>, material: string, minimumPriceToBid: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, mpn: string, pattern: string, paymentMethods: table<paymentInstructions: list, paymentMethodBrands: list, paymentMethodType: string, sellerInstructions: list>, price: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDisplayCondition: string, primaryItemGroup: record<itemGroupAdditionalImages: list<record>, itemGroupHref: string, itemGroupId: string, itemGroupImage: record<height: int, imageUrl: string, width: int>, itemGroupTitle: string, itemGroupType: string>, primaryProductReviewRating: record<averageRating: string, ratingHistograms: list<record>, reviewCount: int>, product: record<additionalImages: list<record>, additionalProductIdentities: list<record>, aspectGroups: list<record>, brand: string, description: string, gtins: list<string>, image: record<height: int, imageUrl: string, width: int>, mpns: list<string>, title: string>, productFicheWebUrl: string, qualifiedPrograms: list<string>, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record<extendedHolidayReturnsOffered: bool, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, seller: record<feedbackPercentage: string, feedbackScore: int, sellerAccountType: string, sellerLegalInfo: record<email: string, fax: string, imprint: string, legalContactFirstName: string, legalContactLastName: string, name: string, phone: string, registrationNumber: string, sellerProvidedLegalAddress: record, termsOfService: string, vatDetails: list>, username: string>, sellerItemRevision: string, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<additionalShippingCostPerUnit: record, cutOffDateUsedForEstimate: string, fulfilledThrough: string, guaranteedDelivery: bool, importCharges: record, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, quantityUsedForEstimate: int, shipToLocationUsedForEstimate: record, shippingCarrierCode: string, shippingCost: record, shippingCostType: string, shippingServiceCode: string, trademarkSymbol: string, type: string>, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: table<ebayCollectAndRemitTax: bool, includedInPrice: bool, shippingAndHandlingTaxed: bool, taxJurisdiction: record, taxPercentage: string, taxType: string>, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, unitPricingMeasure: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    check-compatibility: "record<compatibilityStatus: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    search: "record<autoCorrections: record<q: string>, href: string, itemSummaries: table<additionalImages: list, adultOnly: bool, availableCoupons: bool, bidCount: int, buyingOptions: list, categories: list, compatibilityMatch: string, compatibilityProperties: list, condition: string, conditionId: string, currentBidPrice: record, distanceFromPickupLocation: record, energyEfficiencyClass: string, epid: string, image: record, itemAffiliateWebUrl: string, itemGroupHref: string, itemGroupType: string, itemHref: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, marketingPrice: record, pickupOptions: list, price: record, priceDisplayCondition: string, qualifiedPrograms: list, seller: record, shippingOptions: list, shortDescription: string, thumbnailImages: list, title: string, unitPrice: record, unitPricingMeasure: string>, limit: int, next: string, offset: int, prev: string, refinement: record<aspectDistributions: list<record>, buyingOptionDistributions: list<record>, categoryDistributions: list<record>, conditionDistributions: list<record>, dominantCategoryId: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    search-by-image: "record<autoCorrections: record<q: string>, href: string, itemSummaries: table<additionalImages: list, adultOnly: bool, availableCoupons: bool, bidCount: int, buyingOptions: list, categories: list, compatibilityMatch: string, compatibilityProperties: list, condition: string, conditionId: string, currentBidPrice: record, distanceFromPickupLocation: record, energyEfficiencyClass: string, epid: string, image: record, itemAffiliateWebUrl: string, itemGroupHref: string, itemGroupType: string, itemHref: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, marketingPrice: record, pickupOptions: list, price: record, priceDisplayCondition: string, qualifiedPrograms: list, seller: record, shippingOptions: list, shortDescription: string, thumbnailImages: list, title: string, unitPrice: record, unitPricingMeasure: string>, limit: int, next: string, offset: int, prev: string, refinement: record<aspectDistributions: list<record>, buyingOptionDistributions: list<record>, categoryDistributions: list<record>, conditionDistributions: list<record>, dominantCategoryId: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    get-shopping-cart: "record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    add-item: "record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    remove-item: "record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
    update-quantity: "record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-items" "get-item-by-legacy-id" "get-items-by-item-group" "get-item" "check-compatibility" "search" "search-by-image" "get-shopping-cart" "add-item" "remove-item" "update-quantity" "commands"] | sort) } | get name | first)
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

# This method retrieves the details of specific items that the buyer needs to make a purchasing decision. Note: This is a (Limited Release) available only to select Partners. For this method, only the following fields are returned: eligibleForInlineCheckout, estimatedAvailabilities, itemAffiliateWebURL, itemID, ItemWebURL, legacyItemID, price, sellerItemRevision, and topRatedBuyingExperience. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/item/ Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to be commissioned for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /item/
# Returns: record<items: table<additionalImages: list, adultOnly: bool, ageGroup: string, availableCoupons: list, bidCount: int, brand: string, buyingOptions: list, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: list, gender: string, gtin: string, image: record, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, localizedAspects: list, lotSize: int, marketingPrice: record, material: string, minimumPriceToBid: record, mpn: string, pattern: string, paymentMethods: list, price: record, priceDisplayCondition: string, primaryItemGroup: record, primaryProductReviewRating: record, product: record, productFicheWebUrl: string, qualifiedPrograms: list, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record, seller: record, sellerItemRevision: string, shipToLocations: record, shippingOptions: list, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: list, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record, unitPricingMeasure: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getItems
export def "get-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-ids: string # A list of item IDs. Item IDs are the eBay RESTful identifier of items. RESTful Item ID Format: v1|#|# For example: v1|272394640372|0 or v1|162846450672|461882996982 In any given request, either item_ids or item_group_ids can be retrieved. Attempting to retrieve both will result in an error. In a request, multiple item_ids can be passed as comma separated values. Maximum allowed itemIDs: 20 For more information about item IDs for RESTful APIs, see the Legacy API compatibility section of the Buy APIs Overview.
  --item-group-ids: string # A list of item group IDs. Item group IDs are the eBay RESTful identifier of item groups. RESTful Group Item ID Format: ############ For example: 330017835749 or 330017835740 In any given request, either item_ids or item_group_ids can be retrieved. Attempting to retrieve both will result in an error. In a request, multiple item_group_ids can be passed as comma separated values. Maximum allowed itemGroupIDs: 10
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item/"
    query: [{name: item_ids, var: item_ids}, {name: item_group_ids, var: item_group_ids}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_ids: $item_ids, item_group_ids: $item_group_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method is a bridge between the eBay legacy APIs, such as Shopping, and Finding and the eBay Buy APIs. There are differences between how legacy APIs and RESTful APIs return the identifier of an "item" and what the item ID represents. This method lets you use the legacy item ids retrieve the details of a specific item, such as description, price, and other information the buyer needs to make a purchasing decision. It also returns the RESTful item ID, which you can use with all the Buy API methods. For more information about how to use legacy ids with the Buy APIs, see Legacy API compatibility in the Buying Integration guide. This method returns the item details and requires you to pass in either the item ID of a non-variation item or the item ids of both the parent and child of an item group. An item group is an item that has various aspect differences, such as color, size, storage capacity, etc. When an item group is created, one of the item variations, such as the red shirt size L, is chosen as the "parent". All the other items in the group are the children, such as the blue shirt size L, red shirt size M, etc. The fieldgroups URI parameter lets you control what is returned in the response. Setting fieldgroups to PRODUCT, adds additional fields to the default response that return information about the product of the item. For more information, see fieldgroups. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item/get_item_by_legacy_id/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/item/get_item_by_legacy_id/ Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to be commissioned for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /item/get_item_by_legacy_id
# Returns: record<additionalImages: table<height: int, imageUrl: string, width: int>, adultOnly: bool, ageGroup: string, availableCoupons: table<constraint: string, discountAmount: record, discountType: string, message: string, redemptionCode: string, termsWebUrl: string>, bidCount: int, brand: string, buyingOptions: list<string>, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: table<availabilityThreshold: int, availabilityThresholdType: string, deliveryOptions: list, estimatedAvailabilityStatus: string, estimatedAvailableQuantity: int, estimatedSoldQuantity: int>, gender: string, gtin: string, image: record<height: int, imageUrl: string, width: int>, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, postalCode: string, stateOrProvince: string>, itemWebUrl: string, legacyItemId: string, localizedAspects: table<name: string, type: string, value: string>, lotSize: int, marketingPrice: record<discountAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, discountPercentage: string, originalPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceTreatment: string>, material: string, minimumPriceToBid: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, mpn: string, pattern: string, paymentMethods: table<paymentInstructions: list, paymentMethodBrands: list, paymentMethodType: string, sellerInstructions: list>, price: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDisplayCondition: string, primaryItemGroup: record<itemGroupAdditionalImages: list<record>, itemGroupHref: string, itemGroupId: string, itemGroupImage: record<height: int, imageUrl: string, width: int>, itemGroupTitle: string, itemGroupType: string>, primaryProductReviewRating: record<averageRating: string, ratingHistograms: list<record>, reviewCount: int>, product: record<additionalImages: list<record>, additionalProductIdentities: list<record>, aspectGroups: list<record>, brand: string, description: string, gtins: list<string>, image: record<height: int, imageUrl: string, width: int>, mpns: list<string>, title: string>, productFicheWebUrl: string, qualifiedPrograms: list<string>, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record<extendedHolidayReturnsOffered: bool, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, seller: record<feedbackPercentage: string, feedbackScore: int, sellerAccountType: string, sellerLegalInfo: record<email: string, fax: string, imprint: string, legalContactFirstName: string, legalContactLastName: string, name: string, phone: string, registrationNumber: string, sellerProvidedLegalAddress: record, termsOfService: string, vatDetails: list>, username: string>, sellerItemRevision: string, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<additionalShippingCostPerUnit: record, cutOffDateUsedForEstimate: string, fulfilledThrough: string, guaranteedDelivery: bool, importCharges: record, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, quantityUsedForEstimate: int, shipToLocationUsedForEstimate: record, shippingCarrierCode: string, shippingCost: record, shippingCostType: string, shippingServiceCode: string, trademarkSymbol: string, type: string>, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: table<ebayCollectAndRemitTax: bool, includedInPrice: bool, shippingAndHandlingTaxed: bool, taxJurisdiction: record, taxPercentage: string, taxType: string>, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, unitPricingMeasure: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getItemByLegacyId
export def "get-item-by-legacy-id" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldgroups: string # This field lets you control what is returned in the response. If you do not set this field, the method returns all the details of the item. Note: In this method, the only value supported is PRODUCT. Valid Values: PRODUCT - This adds the additionalImages, additionalProductIdentities, aspectGroups, description, gtins, image, and title fields to the response, which describe the item's product. See Product for more information about these fields. Code so that your app gracefully handles any future changes to this list.
  --legacy-item-id: string # Specifies either: The legacy item ID of an item that is not part of a group. The legacy item ID of a group, which is the ID of the "parent" of the group of items. Note: If you pass in a group ID, you must also use the legacy_variation_id field and pass in the legacy ID of the specific item variation (child ID). Legacy ids are returned by APIs, such as the Finding API. The following is an example of using the value of the ItemID field for a specific item from Finding to get the RESTful itemId value. browse/v1/item/get_item_by_legacy_id?legacy_item_id=110039490209 Maximum: 1 (required)
  --legacy-variation-id: string # Specifies the legacy item ID of a specific item in an item group, such as the red shirt size L. Legacy ids are returned by APIs, such as the Finding API. Maximum: 1 Requirement: You must always pass in the legacy_item_id with the legacy_variation_id
  --legacy-variation-sku: string # Specifics the legacy SKU of the item. SKU are item ids created by the seller. Legacy SKUs are returned by eBay the Shopping API. The following is an example of using the value of the ItemID and SKU fields to get the RESTful itemId value. browse/v1/item/get_item_by_legacy_id?legacy_item_id=110039490209&legacy_variation_sku=V-00031-WHM Maximum: 1 Requirement: You must always pass in the legacy_item_id with the legacy_variation_sku
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item/get_item_by_legacy_id"
    query: [{name: fieldgroups, var: fieldgroups}, {name: legacy_item_id, var: legacy_item_id, required: true}, {name: legacy_variation_id, var: legacy_variation_id}, {name: legacy_variation_sku, var: legacy_variation_sku}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    fieldgroups: $fieldgroups, legacy_item_id: $legacy_item_id, legacy_variation_id: $legacy_variation_id, legacy_variation_sku: $legacy_variation_sku
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details of the individual items in an item group. An item group is an item that has various aspect differences, such as color, size, storage capacity, etc. You pass in the item group ID as a URI parameter. You use this method to show the item details of items with multiple aspects, such as color, size, storage capacity, etc. This method returns two main containers; items and commonDescriptions. The items container has an array of containers with the details of each item in the group. The commonDescriptions container has an array of containers for a description and the item ids of all the items that have this exact description. Because items within an item group often have the same description, this decreases the size of the response. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item/get_items_by_item_group/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/item/get_items_by_item_group/ Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to be commissioned for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /item/get_items_by_item_group
# Returns: record<commonDescriptions: table<description: string, itemIds: list>, items: table<additionalImages: list, adultOnly: bool, ageGroup: string, availableCoupons: list, bidCount: int, brand: string, buyingOptions: list, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: list, gender: string, gtin: string, image: record, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, localizedAspects: list, lotSize: int, marketingPrice: record, material: string, minimumPriceToBid: record, mpn: string, pattern: string, paymentMethods: list, price: record, priceDisplayCondition: string, primaryItemGroup: record, primaryProductReviewRating: record, product: record, productFicheWebUrl: string, qualifiedPrograms: list, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record, seller: record, sellerItemRevision: string, shipToLocations: record, shippingOptions: list, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: list, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record, unitPricingMeasure: string, warnings: list>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getItemsByItemGroup
export def "get-items-by-item-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-group-id: string # Identifier of the item group to return. An item group is an item that has various aspect differences, such as color, size, storage capacity, etc. This ID is returned in the itemGroupHref field of the search and getItem methods. For Example: https://api.ebay.com/buy/browse/v1/item/get_items_by_item_group?item_group_id=351825690866 (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item/get_items_by_item_group"
    query: [{name: item_group_id, var: item_group_id, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_group_id: $item_group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method retrieves the details of a specific item, such as description, price, category, all item aspects, condition, return policies, seller feedback and score, shipping options, shipping costs, estimated delivery, and other information the buyer needs to make a purchasing decision. The Buy APIs are designed to let you create an eBay shopping experience in your app or website. This means you will need to know when something, such as the availability, quantity, etc., has changed in any eBay item you are offering. You can do this easily by setting the fieldgroups URI parameter. This parameter lets you control what is returned in the response. Setting fieldgroups to COMPACT reduces the response to only the five fields that you need in order to check if any item detail has changed. Setting fieldgroups to PRODUCT, adds additional fields to the default response that return information about the product of the item. You can use either COMPACT or PRODUCT but not both. For more information, see fieldgroups. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/item/ Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to be commissioned for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /item/{item_id}
# Returns: record<additionalImages: table<height: int, imageUrl: string, width: int>, adultOnly: bool, ageGroup: string, availableCoupons: table<constraint: string, discountAmount: record, discountType: string, message: string, redemptionCode: string, termsWebUrl: string>, bidCount: int, brand: string, buyingOptions: list<string>, categoryId: string, categoryPath: string, color: string, condition: string, conditionDescription: string, conditionId: string, currentBidPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, description: string, eligibleForInlineCheckout: bool, enabledForGuestCheckout: bool, energyEfficiencyClass: string, epid: string, estimatedAvailabilities: table<availabilityThreshold: int, availabilityThresholdType: string, deliveryOptions: list, estimatedAvailabilityStatus: string, estimatedAvailableQuantity: int, estimatedSoldQuantity: int>, gender: string, gtin: string, image: record<height: int, imageUrl: string, width: int>, inferredEpid: string, itemAffiliateWebUrl: string, itemEndDate: string, itemId: string, itemLocation: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, postalCode: string, stateOrProvince: string>, itemWebUrl: string, legacyItemId: string, localizedAspects: table<name: string, type: string, value: string>, lotSize: int, marketingPrice: record<discountAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, discountPercentage: string, originalPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceTreatment: string>, material: string, minimumPriceToBid: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, mpn: string, pattern: string, paymentMethods: table<paymentInstructions: list, paymentMethodBrands: list, paymentMethodType: string, sellerInstructions: list>, price: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDisplayCondition: string, primaryItemGroup: record<itemGroupAdditionalImages: list<record>, itemGroupHref: string, itemGroupId: string, itemGroupImage: record<height: int, imageUrl: string, width: int>, itemGroupTitle: string, itemGroupType: string>, primaryProductReviewRating: record<averageRating: string, ratingHistograms: list<record>, reviewCount: int>, product: record<additionalImages: list<record>, additionalProductIdentities: list<record>, aspectGroups: list<record>, brand: string, description: string, gtins: list<string>, image: record<height: int, imageUrl: string, width: int>, mpns: list<string>, title: string>, productFicheWebUrl: string, qualifiedPrograms: list<string>, quantityLimitPerBuyer: int, reservePriceMet: bool, returnTerms: record<extendedHolidayReturnsOffered: bool, refundMethod: string, restockingFeePercentage: string, returnInstructions: string, returnMethod: string, returnPeriod: record<unit: string, value: int>, returnShippingCostPayer: string, returnsAccepted: bool>, seller: record<feedbackPercentage: string, feedbackScore: int, sellerAccountType: string, sellerLegalInfo: record<email: string, fax: string, imprint: string, legalContactFirstName: string, legalContactLastName: string, name: string, phone: string, registrationNumber: string, sellerProvidedLegalAddress: record, termsOfService: string, vatDetails: list>, username: string>, sellerItemRevision: string, shipToLocations: record<regionExcluded: list<record>, regionIncluded: list<record>>, shippingOptions: table<additionalShippingCostPerUnit: record, cutOffDateUsedForEstimate: string, fulfilledThrough: string, guaranteedDelivery: bool, importCharges: record, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, quantityUsedForEstimate: int, shipToLocationUsedForEstimate: record, shippingCarrierCode: string, shippingCost: record, shippingCostType: string, shippingServiceCode: string, trademarkSymbol: string, type: string>, shortDescription: string, size: string, sizeSystem: string, sizeType: string, subtitle: string, taxes: table<ebayCollectAndRemitTax: bool, includedInPrice: bool, shippingAndHandlingTaxed: bool, taxJurisdiction: record, taxPercentage: string, taxType: string>, title: string, topRatedBuyingExperience: bool, uniqueBidderCount: int, unitPrice: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, unitPricingMeasure: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getItem
export def "get-item" [
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
  --fieldgroups: string # This parameter lets you control what is returned in the response. If you do not set this field, the method returns all the details of the item. Valid Values: PRODUCT - This adds the additionalImages, additionalProductIdentities, aspectGroups, description, gtins, image, and title product fields to the response, which describe the product associated with the item. See Product for more information about these fields. COMPACT - This returns only the following fields, which let you quickly check if the availability or price of the item has changed, if the item has been revised by the seller, or if an item's top-rated plus status has changed for items you have stored. itemId - The identifier of the item. itemAffiliateWebURL - The URL of the View Item page of the item, which includes the affiliate tracking ID. This field is only returned if the eBay partner enables affiliate tracking for the item by including the X-EBAY-C-ENDUSERCTX request header in the method. ItemWebURL - The URL of the View Item page of the item. This enables you to include a "Report Item on eBay" link that takes the buyer to the View Item page on eBay. From there they can report any issues regarding this item to eBay. legacyItemId - The unique identifier of the eBay listing that contains the item. This is the traditional/legacy ID that is often seen in the URL of the listing View Item page. sellerItemRevision - An identifier generated/incremented when a seller revises the item. The follow are the two types of item revisions: Seller changes, such as changing the title eBay system changes, such as changing the quantity when an item is purchased. This ID is changed only when the seller makes a change to the item. This means you cannot use this value to determine if the quantity has changed. To check if the quantity has changed, use estimatedAvailabilities. topRatedBuyingExperience - A boolean value indicating if this item is a top-rated plus item. A change in the item's top rated plus standing is not tracked by the revision ID. See topRatedBuyingExperience for more information. price - This is tracked by the revision ID but is returned here to enable you to quickly verify the price of the item. estimatedAvailabilities - Returns the item availability information, which is based on the item's quantity. Note: Changes in quantity are not tracked by sellerItemRevision. itemEndDate - This is the scheduled end time of the listing. eligibleForInlineCheckout - This parameter returns items based on whether or not the items can be purchased using the Buy Order API. If the value of this field is true, this indicates that the item can be purchased using the Order API. If the value of this field is false, this indicates that the item cannot be purchased using the Order API and must be purchased on the eBay site. For Example To check if a stored item's information is current, do following. Pass in the item ID and set fieldgroups to COMPACT. item/v1|46566502948|0?fieldgroups=COMPACT Do one of the following: If the sellerItemRevision field is returned and you haven't stored a revision number for this item, record the number and pass in the item ID in the getItem method to get the latest information. If the revision number is different from the value you have stored, update the value and pass in the item ID in the getItem method to get the latest information. If the sellerItemRevision field is not returned or has not changed, where needed, update the item information with the information returned in the response. Maximum value: 1 If more than one values is specified, the first value will be used.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item/{item_id}"
    path_params: [{name: item_id, var: item_id}]
    query: [{name: fieldgroups, var: fieldgroups}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, fieldgroups: $fieldgroups
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method checks if a product is compatible with the specified item. You can use this method to check the compatibility of cars, trucks, and motorcycles with a specific part listed on eBay. For example, to check the compatibility of a part, you pass in the item ID of the part as a URI parameter and specify all the attributes used to define a specific car in the compatibilityProperties container. If the call is successful, the response will be COMPATIBLE, NOT_COMPATIBLE, or UNDETERMINED. See compatibilityStatus for details. Note: The only products supported are cars, trucks, and motorcycles. To find the attributes and values for a specific marketplace, you can use the compatibility methods in the Taxonomy API. You can use this data to create menus to help buyers specify the product, such as their car. For more details and a list of the required attributes for the US marketplace that describe motor vehicles, see Check compatibility in the Buy Integration Guide. For an example, see the Samples section. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item/ Note: This method is supported only on Production. Restrictions For a list of supported sites and other restrictions, see API Restrictions.
#
# POST /item/{item_id}/check_compatibility
# Returns: record<compatibilityStatus: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: checkCompatibility
export def "check-compatibility" [
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
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace you want to use. Note: This value is case sensitive. For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions. (required)
  --compatibility-properties: list # An array of attribute name/value pairs used to define a specific product. For example: If you wanted to specify a specific car, one of the name/value pairs would be "name" : "Year", "value" : "2019" For a list of the attributes required for cars and trucks and motorcycles see Check compatibility in the Buy Integration Guide. — item shape: {name?: string, value?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/item/{item_id}/check_compatibility"
    path_params: [{name: item_id, var: item_id}]
    header: [{name: X-EBAY-C-MARKETPLACE-ID, var: x_ebay_c_marketplace_id, required: true}]
    body: {content_type: "application/json", kind: json, fields: [{name: compatibilityProperties, var: compatibility_properties}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    item_id: $item_id, x_ebay_c_marketplace_id: $x_ebay_c_marketplace_id, compatibility_properties: $compatibility_properties
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This method searches for eBay items by various query parameters and retrieves summaries of the items. You can search by keyword, category, eBay product ID (ePID), or GTIN, charity ID, or a combination of these. Note: Only FIXED_PRICE (Buy It Now) items are returned by default. However, this method does return items where both FIXED_PRICE and AUCTION are available as a buying option. After a bid has been placed, items become active auction items and are no longer returned by default, but they remain accessible by filtering for the AUCTION buying option. This method also supports the following: Filtering by the value of one or multiple fields, such as listing format, item condition, price range, location, and more. For the fields supported by this method, see the filter parameter. Retrieving the refinements (metadata) of an item , such as item aspects (color, brand), condition, category, etc. using the fieldgroups parameter. Filtering by item aspects and other refinements using the aspect_filter parameter. Filtering for items that are compatible with a specific product, using the compatibility_filter parameter. Creating aspects histograms, which enables shoppers to drill down in each refinement narrowing the search results. For details and examples of these capabilities, see Browse API in the Buying Integration Guide. Pagination and sort controls There are pagination controls (limit and offset fields) and sort query parameters that control/sort the data that is returned. By default, the results are sorted by "Best Match". For more information about Best Match, see the eBay help page Best Match. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item_summary/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/item_summary/ Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# GET /item_summary/search
# Returns: record<autoCorrections: record<q: string>, href: string, itemSummaries: table<additionalImages: list, adultOnly: bool, availableCoupons: bool, bidCount: int, buyingOptions: list, categories: list, compatibilityMatch: string, compatibilityProperties: list, condition: string, conditionId: string, currentBidPrice: record, distanceFromPickupLocation: record, energyEfficiencyClass: string, epid: string, image: record, itemAffiliateWebUrl: string, itemGroupHref: string, itemGroupType: string, itemHref: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, marketingPrice: record, pickupOptions: list, price: record, priceDisplayCondition: string, qualifiedPrograms: list, seller: record, shippingOptions: list, shortDescription: string, thumbnailImages: list, title: string, unitPrice: record, unitPricingMeasure: string>, limit: int, next: string, offset: int, prev: string, refinement: record<aspectDistributions: list<record>, buyingOptionDistributions: list<record>, categoryDistributions: list<record>, conditionDistributions: list<record>, dominantCategoryId: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: search
export def "search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect-filter: string # This field lets you filter by item aspects. The aspect name/value pairs and category, which is required, is used to limit the results to specific aspects of the item. For example, in a clothing category one aspect pair would be Color/Red. For example, the method below uses the category ID for Women's Clothing. This will return only items for a woman's red shirt. /buy/browse/v1/item_summary/search?q=shirt&category_ids=15724&aspect_filter=categoryId:15724,Color:{Red} To get a list of the aspects pairs and the category, which is returned in the dominantCategoryId field, set fieldgroups to ASPECT_REFINEMENTS. /buy/browse/v1/item_summary/search?q=shirt&fieldgroups=ASPECT_REFINEMENTS Required: The category ID is required twice; once as a URI parameter and as part of the aspect_filter. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/gct:AspectFilter
  --auto-correct: string # A query parameter that enables auto correction. Valid Values: KEYWORD
  --category-ids: string # The category ID is used to limit the results. This field can have one category ID or a comma separated list of IDs. For example: /buy/browse/v1/item_summary/search?category_ids=29792 Note: Currently, you can pass in only one category ID per request. You can also use any combination of the category_Ids, epid, and q fields. This gives you additional control over the result set. For example, let's say you are looking of a toy phone. If you search for "phone", the result set will be mobile phones because this is the "Best Match" for this search. But if you also include the toy category ID, the results will be what you wanted. For example: /buy/browse/v1/item_summary/search?q=phone&category_ids=220 The list of eBay category IDs is not published and category IDs are not the same across all the eBay marketplaces. You can use the following techniques to find a category by site: Use the Category Changes page. Use the Taxonomy API. For details see Get Categories for Buy APIs. Submit the following method to get the dominantCategoryId for an item. /buy/browse/v1/item_summary/search?q= keyword&fieldgroups=ASPECT_REFINEMENTS Note: If a top-level (L1) category is specified, you must also include the q query parameter. Required: The method must have category_ids, epid, gtin, or q (or any combination of these)
  --charity-ids: string # The charity ID is used to limit the results to only items associated with the specified charity. This field can have one charity ID or a comma separated list of IDs. The method will return all the items associated with the specified charities. For example: /buy/browse/v1/item_summary/search?charity_ids=13-1788491,300108469 The charity ID is the charity's registration ID, also known as the Employer Identification Number (EIN). In GB, it is the Charity Registration Number (CRN), commonly called "Charity Number". To find the charities eBay supports, you can search for a charity at Charity Search or go to Charity Shop. To find the charity ID of a specific charity, click on a charity and use the EIN number. For example, the charity ID for American Red Cross, is 530196605. You can also use any combination of the category_Ids and q fields with a charity_Ids to filter the result set. This gives you additional control over the result set. Restriction: This is supported only on the US and GB marketplaces. Maximum: 20 IDs Required: One ID
  --compatibility-filter: string # This field specifies the attributes used to define a specific product. The service searches for items matching the keyword or matching the keyword and a product attribute value in the title of the item. For example, if the keyword is brakes and compatibility-filter=Year:2018;Make:Honda, the items returned are items with brakes, 2018, or Honda in the title. The service uses the product attributes to determine if the item is compatible. The service returns the attributes that are compatible and the CompatibilityMatchEnum value that indicates how well the item matches the attributes. For the best compatibility results, submit all the attributes used to define the product. Best Practice: Submit all the product attributes for the specific product. For more details, see Check compatibility in the Buy Integration Guide. Note: The only products supported are cars, trucks, and motorcycles. For an example, see the Samples section. Note: Testing in Sandbox is only supported using mock data. See Testing search in the Sandbox for details. Required: q (keyword) one fitment supported category ID (such as 33559 Brakes) a least one product attribute name/value pair For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/gct:CompatibilityFilter
  --epid: string # The ePID is the eBay product identifier of a product from the eBay product catalog. This field limits the results to only items in the specified ePID. The Marketing API getMerchandisedProducts method and the Browse API getItem, getItemByLegacyId, and getItemsByItemGroup calls return the ePID of the product. You can also use the product_summary/search method in the Catalog API to search for the ePID of the product. For example: /buy/browse/v1/item_summary/search?epid=15032 Maximum: 1 Required: The method must have category_ids, epid, gtin, or q (or any combination of these)
  --fieldgroups: string # This field is a comma separated list of values that lets you control what is returned in the response. The default is MATCHING_ITEMS, which returns the items that match the keyword or category specified. The other values return data that can be used to create histograms or provide additional information. Valid Values: ASPECT_REFINEMENTS - This returns the aspectDistributions container, which has the dominantCategoryId, matchCount, and refinementHref for the various aspects of the items found. For example, if you searched for 'Mustang', some of the aspect would be Model Year, Exterior Color, Vehicle Mileage, etc. Note: ASPECT_REFINEMENTS are category specific. BUYING_OPTION_REFINEMENTS - This returns the buyingOptionDistributions container, which has the matchCount and refinementHref for AUCTION and FIXED_PRICE (Buy It Now) items. Note: Classified items are not supported and only "Buy It Now" (non-auction) items are returned. CATEGORY_REFINEMENTS - This returns the categoryDistributions container, which has the categories that the item is in. CONDITION_REFINEMENTS - This returns the conditionDistributions container, such as NEW, USED, etc. Within these groups are multiple states of the condition. For example, New can be New without tag, New in box, New without box, etc. EXTENDED - This returns the shortDescription field, which provides condition and item aspect information and the itemLocation.city field. MATCHING_ITEMS - This is meant to be used with one or more of the refinement values above. You use this to return the specified refinements and all the matching items. FULL - This returns all the refinement containers and all the matching items. Code so that your app gracefully handles any future changes to this list. Default: MATCHING_ITEMS
  --filter: string # This field supports multiple field filters that can be used to limit/customize the result set. For example: /buy/browse/v1/item_summary/search?q=shirt&filter=price:[10..50] You can also combine filters. /buy/browse/v1/item_summary/search?q=shirt&filter=price:[10..50],sellers:{rpseller|bigSal} The following are the supported filters. For details and examples for all the filters, see Buy API Field Filters. buyingOptions charityOnly conditionIds conditions deliveryCountry deliveryOptions deliveryPostalCode excludeCategoryIds excludeSellers guaranteedDeliveryInDays itemEndDate itemLocationCountry itemStartDate paymentMethods pickupCountry pickupPostalCode pickupRadius pickupRadiusUnit price priceCurrency qualifiedPrograms maxDeliveryCost (free shipping) returnsAccepted sellerAccountTypes sellers For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/cos:FilterField
  --gtin: string # This field lets you search by the Global Trade Item Number of the item as defined by https://www.gtin.info. You can search only by UPC (Universal Product Code). If you have other formats of GTIN, you need to search by keyword. For example: /buy/browse/v1/item_summary/search?gtin=099482432621 Maximum: 1 Required: The method must have category_ids, epid, gtin, or q (or any combination of these)
  --limit: string # The number of items, from the result set, returned in a single page. Default: 50 Maximum number of items per page (limit): 200 Maximum number of items in a result set: 10,000
  --offset: string # Specifies the number of items to skip in the result set. This is used with the limit field to control the pagination of the output. If offset is 0 and limit is 10, the method will retrieve items 1-10 from the list of items returned, if offset is 10 and limit is 10, the method will retrieve items 11 thru 20 from the list of items returned. Valid Values: 0-10,000 (inclusive) Default: 0 Maximum number of items returned: 10,000
  --q: string # A string consisting of one or more keywords that are used to search for items on eBay. The keywords are handled as follows: If the keywords are separated by a comma, it is treated as an AND. In the following example, the query returns items that have iphone AND ipad. /buy/browse/v1/item_summary/search?q=iphone,ipad If the keywords are separated by a space, it is treated as an OR. In the following examples, the query returns items that have iphone OR ipad. /buy/browse/v1/item_summary/search?q=iphone ipad /buy/browse/v1/item_summary/search?q=iphone, ipad Restriction: The * wildcard character is not allowed in this field. Required: The method must have category_ids, epid, gtin, or q (or any combination of these)
  --sort: string # Specifies the order and the field name to use to sort the items. You can sort items by price (in ascending or descending order) or by distance (only applicable if the "pickup" filters are used, and only ascending order is supported). You can also sort items by listing date, with the most recently listed (newest) items appearing first. Note: To sort in descending order, insert a hyphen (-) before the field name. If no sort parameter is submitted, the result set is sorted by "Best Match". The following are examples of using the sort query parameter. Sort Result sort=price Sorts by price in ascending order (lowest price first) sort=-price Sorts by price in descending order (highest price first) sort=distance Sorts by distance in ascending order (shortest distance first) sort=newlyListed Sorts by listing date (most recently listed/newest items first) Default: Ascending For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/cos:SortField
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/item_summary/search"
    query: [{name: aspect_filter, var: aspect_filter}, {name: auto_correct, var: auto_correct}, {name: category_ids, var: category_ids}, {name: charity_ids, var: charity_ids}, {name: compatibility_filter, var: compatibility_filter}, {name: epid, var: epid}, {name: fieldgroups, var: fieldgroups}, {name: filter, var: filter}, {name: gtin, var: gtin}, {name: limit, var: limit}, {name: offset, var: offset}, {name: q, var: q}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aspect_filter: $aspect_filter, auto_correct: $auto_correct, category_ids: $category_ids, charity_ids: $charity_ids, compatibility_filter: $compatibility_filter, epid: $epid, fieldgroups: $fieldgroups, filter: $filter, gtin: $gtin, limit: $limit, offset: $offset, q: $q, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an Experimental method. This method searches for eBay items based on a image and retrieves summaries of the items. You pass in a Base64 image in the request payload and can refine the search by category, or eBay product ID (ePID), or a combination of these using URI parameters. To get the Base64 image string, you can use sites such as https://codebeautify.org/image-to-base64-converter. This method also supports the following: Filtering by the value of one or multiple fields, such as listing format, item condition, price range, location, and more. For the fields supported by this method, see the filter parameter. Filtering by item aspects using the aspect_filter parameter. For details and examples of these capabilities, see Browse API in the Buying Integration Guide. Pagination and sort controls There are pagination controls (limit and offset fields) and sort query parameters that control/sort the data that is returned. By default, the results are sorted by "Best Match". For more information about Best Match, see the eBay help page Best Match. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/item_summary/search_by_image/ Sandbox URL: Due to the data available, this method is not supported in the eBay Sandbox. To test your integration, use the Production URL. Request headers This method uses the X-EBAY-C-ENDUSERCTX request header to support revenue sharing for eBay Partner Networks and to improve the accuracy of shipping and delivery time estimations. For details see, Request headers in the Buying Integration Guide. URL Encoding for Parameters Query parameter values need to be URL encoded. For details, see URL encoding query parameter values. For readability, code examples in this document have not been URL encoded. Restrictions This method can return a maximum of 10,000 items. For a list of supported sites and other restrictions, see API Restrictions. eBay Partner Network: In order to receive a commission for your sales, you must use the URL returned in the itemAffiliateWebUrl field to forward your buyer to the ebay.com site.
#
# POST /item_summary/search_by_image
# Returns: record<autoCorrections: record<q: string>, href: string, itemSummaries: table<additionalImages: list, adultOnly: bool, availableCoupons: bool, bidCount: int, buyingOptions: list, categories: list, compatibilityMatch: string, compatibilityProperties: list, condition: string, conditionId: string, currentBidPrice: record, distanceFromPickupLocation: record, energyEfficiencyClass: string, epid: string, image: record, itemAffiliateWebUrl: string, itemGroupHref: string, itemGroupType: string, itemHref: string, itemId: string, itemLocation: record, itemWebUrl: string, legacyItemId: string, marketingPrice: record, pickupOptions: list, price: record, priceDisplayCondition: string, qualifiedPrograms: list, seller: record, shippingOptions: list, shortDescription: string, thumbnailImages: list, title: string, unitPrice: record, unitPricingMeasure: string>, limit: int, next: string, offset: int, prev: string, refinement: record<aspectDistributions: list<record>, buyingOptionDistributions: list<record>, categoryDistributions: list<record>, conditionDistributions: list<record>, dominantCategoryId: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: searchByImage
export def "search-by-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect-filter: string # This field lets you filter by item aspects. The aspect name/value pairs and category, which is required, is used to limit the results to specific aspects of the item. For example, in a clothing category one aspect pair would be Color/Red. For example, the method below uses the category ID for Women's Clothing. This will return only items for a woman's red shirt. category_ids=15724&aspect_filter=categoryId:15724,Color:{Red} Required: The category ID is required twice; once as a URI parameter and as part of the aspect_filter. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/gct:AspectFilter
  --category-ids: string # The category ID is used to limit the results. This field can have one category ID or a comma separated list of IDs. Note: Currently, you can pass in only one category ID per request. You can also use any combination of the category_Ids and epid fields. This gives you additional control over the result set. The list of eBay category IDs is not published and category IDs are not the same across all the eBay marketplaces. You can use the following techniques to find a category by site: Use the Category Changes page. Use the Taxonomy API. For details see Get Categories for Buy APIs. Submit the following method to get the dominantCategoryId for an item. /buy/browse/v1/item_summary/search?q= keyword&fieldgroups=ASPECT_REFINEMENTS Required: The method must have category_ids or epid (or any combination of these)
  --charity-ids: string # The charity ID is used to limit the results to only items associated with the specified charity. This field can have one charity ID or a comma separated list of IDs. The method will return all the items associated with the specified charities. For example: /buy/browse/v1/item_summary/search?charity_ids=13-1788491,300108469 The charity ID is the charity's registration ID, also known as the Employer Identification Number (EIN). In GB, it is the Charity Registration Number (CRN), commonly called "Charity Number". To find the charities eBay supports, you can search for a charity at Charity Search or go to Charity Shop. To find the charity ID of a specific charity, click on a charity and use the EIN number. For example, the charity ID for American Red Cross, is 530196605. You can also use any combination of the category_Ids and q fields with a charity_Ids to filter the result set. This gives you additional control over the result set. Restriction: This is supported only on the US and GB marketplaces. Maximum: 20 IDs Required: One ID
  --fieldgroups: string # This field is a comma separated list of values that lets you control what is returned in the response. The default is MATCHING_ITEMS, which returns the items that match the keyword or category specified. The other values return data that can be used to create histograms or provide additional information. Valid Values: ASPECT_REFINEMENTS - This returns the aspectDistributions container, which has the dominantCategoryId, matchCount, and refinementHref for the various aspects of the items found. For example, if you searched for 'Mustang', some of the aspect would be Model Year, Exterior Color, Vehicle Mileage, etc. Note: ASPECT_REFINEMENTS are category specific. BUYING_OPTION_REFINEMENTS - This returns the buyingOptionDistributions container, which has the matchCount and refinementHref for AUCTION and FIXED_PRICE (Buy It Now) items. Note: Classified items are not supported and only "Buy It Now" (non-auction) items are returned. CATEGORY_REFINEMENTS - This returns the categoryDistributions container, which has the categories that the item is in. CONDITION_REFINEMENTS - This returns the conditionDistributions container, such as NEW, USED, etc. Within these groups are multiple states of the condition. For example, New can be New without tag, New in box, New without box, etc. EXTENDED - This returns the shortDescription field, which provides condition and item aspect information and the itemLocation.city field. MATCHING_ITEMS - This is meant to be used with one or more of the refinement values above. You use this to return the specified refinements and all the matching items. FULL - This returns all the refinement containers and all the matching items. Code so that your app gracefully handles any future changes to this list. Default: MATCHING_ITEMS
  --filter: string # This field supports multiple field filters that can be used to limit/customize the result set. For example: /buy/browse/v1/item_summary/search?q=shirt&filter=price:[10..50] You can also combine filters. /buy/browse/v1/item_summary/search?q=shirt&filter=price:[10..50],sellers:{rpseller|bigSal} The following are the supported filters. For details and examples for all the filters, see Buy API Field Filters. buyingOptions charityOnly conditionIds conditions deliveryCountry deliveryOptions deliveryPostalCode excludeCategoryIds excludeSellers guaranteedDeliveryInDays itemEndDate itemLocationCountry itemStartDate paymentMethods pickupCountry pickupPostalCode pickupRadius pickupRadiusUnit price priceCurrency maxDeliveryCost (free shipping) returnsAccepted sellerAccountTypes sellers For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/cos:FilterField
  --limit: string # The number of items, from the result set, returned in a single page. Default: 50 Maximum number of items per page (limit): 200 Maximum number of items in a result set: 10,000
  --offset: string # The number of items to skip in the result set. This is used with the limit field to control the pagination of the output. If offset is 0 and limit is 10, the method will retrieve items 1-10 from the list of items returned, if offset is 10 and limit is 10, the method will retrieve items 11 thru 20 from the list of items returned. Valid Values: 0-10,000 (inclusive) Default: 0 Maximum number of items returned: 10,000
  --sort: string # Specifies the order and the field name to use to sort the items. You can sort items by price (in ascending or descending order) or by distance (only applicable if the "pickup" filters are used, and only ascending order is supported). You can also sort items by listing date, with the most recently listed (newest) items appearing first. Note: To sort in descending order, insert a hyphen (-) before the field name. If no sort parameter is submitted, the result set is sorted by "Best Match". The following are examples of using the sort query parameter. Sort Result sort=price Sorts by price in ascending order (lowest price first) sort=-price Sorts by price in descending order (highest price first) sort=distance Sorts by distance in ascending order (shortest distance first) sort=newlyListed Sorts by listing date (most recently listed/newest items first) Default: Ascending For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/browse/types/cos:SortField
  --image: string # The Base64 string of the image.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/item_summary/search_by_image"
    query: [{name: aspect_filter, var: aspect_filter}, {name: category_ids, var: category_ids}, {name: charity_ids, var: charity_ids}, {name: fieldgroups, var: fieldgroups}, {name: filter, var: filter}, {name: limit, var: limit}, {name: offset, var: offset}, {name: sort, var: sort}]
    body: {content_type: "application/json", kind: json, fields: [{name: image, var: image}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    aspect_filter: $aspect_filter, category_ids: $category_ids, charity_ids: $charity_ids, fieldgroups: $fieldgroups, filter: $filter, limit: $limit, offset: $offset, sort: $sort, image: $image
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an experimental method. This method retrieves all the items in the eBay member's cart; items added to the cart while on ebay.com as well as items added to the cart using the Browse API. There are no URI parameters or request payload. The response returns the summary details of all the items in the eBay member's cart; items added to the cart while on ebay.com as well as items added to the cart using the Browse API. If the cart is empty, the response is HTTP 204. The quantity and state of an item changes often. If the item becomes "unavailable" such as, when the listing has ended or the item is out of stock, the item will be returned in the unavailableCartItems container. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/shopping_cart/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/shopping_cart/ Note: This method is not available in the eBay API Explorer. Restrictions This method can be used only for eBay members. For a list of supported sites and other restrictions, see API Restrictions.
#
# GET /shopping_cart/
# Returns: record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: getShoppingCart
export def "get-shopping-cart" [
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
    path: "/shopping_cart/"
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an Experimental method. This method creates an eBay cart for the eBay member, if one does not exist, and adds items to that cart. Because a cart never expires, any item added to the cart will remain in the cart until it is removed. To use this method, you must submit a RESTful item ID and the quantity of the item. If the quantity value is greater than the number of available, the quantity value is changed to the number available and a warning is returned. For example, if there are 15 baseballs available and you set the quantity value to 50, the service automatically changes the value of quantity to 15. The response returns all the items in the eBay member's cart; items added to the cart while on ebay.com as well as items added to the cart using the Browse API. The quantity and state of an item changes often. If the item becomes "unavailable" such as, when the listing has ended or the item is out of stock, whether it has just been added to the cart or has been in the cart for some time, the item will be returned in the unavailableCartItems container. Note: There are differences between how legacy APIs, such as Finding, and RESTful APIs, such as Browse, return the identifier of an "item" and what the item ID represents. If you have an item ID from one of the legacy APIs, you can use the legacy item ID with the getItemByLegacyId method to retrieve the RESTful ID for that item. For more information about how to use legacy IDs with the Buy APIs, see Legacy API compatibility in the Buying Integration guide. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/shopping_cart/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/shopping_cart/ Note: This method is not available in the eBay API Explorer. Restrictions This method can be used only for eBay members. You can add only items with a FIXED_PRICE that accept PayPal as a payment. For a list of supported sites and other restrictions, see API Restrictions.
#
# POST /shopping_cart/add_item
# Returns: record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: addItem
export def "add-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-id: string # The eBay RESTful identifier of the item you want added to the cart. RESTful Item ID Format: v1|#|# For example: v1|272394640372|0 v1|162846450672|461882996982 For more information about item ID for RESTful APIs, see the Legacy API compatibility section of the Buy APIs Overview. Maximum number of items in a cart: 100
  --quantity: int # The number of this item the buyer wants to purchase. If this value is greater than the number available, the service will change this value to the number available. If this happens, a warning is returned. Maximum: number available
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shopping_cart/add_item"
    body: {content_type: "application/json", kind: json, fields: [{name: itemId, var: item_id}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    item_id: $item_id, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an experimental method. This method removes a specific item from the eBay member's cart. You specify the ID of the item in the cart (cartItemId) that you want to remove. The response returns all the items in the eBay member's cart; items added to the cart while on ebay.com as well as items added to the cart using the Browse API. If you remove the last item in the cart, the response is HTTP 204. The quantity and state of an item changes often. If the item becomes "unavailable" such as, when the listing has ended or the item is out of stock, the item will be returned in the unavailableCartItems container. Note: The cartItemId is not the same as the item ID. The cartItemId is the identifier of a specific item in the cart and is generated when the item was added to the cart. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/shopping_cart/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/shopping_cart/ Note: This method is not available in the eBay API Explorer. Restrictions This method can be used only for eBay members. For a list of supported sites and other restrictions, see API Restrictions.
#
# POST /shopping_cart/remove_item
# Returns: record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: removeItem
export def "remove-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart-item-id: string # The identifier of the item in the cart to be removed. This ID is generated when the item was added to the cart.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shopping_cart/remove_item"
    body: {content_type: "application/json", kind: json, fields: [{name: cartItemId, var: cart_item_id}]}
    accept: ["application/json"]
    ok: [200, 204]
    auth: bearer
  } {
    cart_item_id: $cart_item_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# This is an experimental method. This method updates the quantity value of a specific item in the eBay member's cart. You specify the ID of the item in the cart (cartItemId) and the new value for the quantity. If the quantity value is greater than the number of available, the quantity value is changed to the number available and a warning is returned. For example, if there are 15 baseballs available and you set the quantity value to 50, the service automatically changes the value of quantity to 15. The response returns all the items in the eBay member's cart; items added to the cart while on ebay.com as well as items added to the cart using the Browse API. The quantity and state of an item changes often. If the item becomes "unavailable" such as, the listing has ended or the item is out of stock, the item will be returned in the unavailableCartItems container. Note: The cartItemId is not the same as the item ID. The cartItemId is the identifier of a specific item in the cart and is generated when the item was added to the cart. URLs for this method Production URL: https://api.ebay.com/buy/browse/v1/shopping_cart/ Sandbox URL: https://api.sandbox.ebay.com/buy/browse/v1/shopping_cart/ Note: This method is not available in the eBay API Explorer. Restrictions This method can be used only for eBay members. For a list of supported sites and other restrictions, see API Restrictions.
#
# POST /shopping_cart/update_quantity
# Returns: record<cartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, cartSubtotal: record<currency: string, value: string>, cartWebUrl: string, unavailableCartItems: table<cartItemId: string, cartItemSubtotal: record, image: record, itemId: string, itemWebUrl: string, price: record, quantity: int, title: string>, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>>
# operationId: updateQuantity
export def "update-quantity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart-item-id: string # The identifier of the item in the cart to be updated. This ID is generated when the item was added to the cart.
  --quantity: int # The new quantity for the item that is being updated.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/shopping_cart/update_quantity"
    body: {content_type: "application/json", kind: json, fields: [{name: cartItemId, var: cart_item_id}, {name: quantity, var: quantity}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    cart_item_id: $cart_item_id, quantity: $quantity
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
