# Auto-generated client for Etherpad API v1.2.15
# Source: https://api.apis.guru/v2/specs/etherpad.local/1.2.15/openapi.json
# Auth: --token flag or $env.ETHERPAD_API_TOKEN

const CLIENT = {
  base_url: "http://etherpad.local"
  token_env_var: "ETHERPAD_API_TOKEN"
  timeout: 30min
  default_headers: {}
  auth_schemes: [
    {name: query-apikey, in: query, header_name: apikey, prefix: ""}
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

def base-url-completer [] { ["http://etherpad.local" "http://pads.mro.name/api/1.2.15"] }
def auth-scheme-completer [] { ["query-apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    append-chat-message-using-get: "record<code: int, data: record, message: string>"
    append-chat-message-using-post: "record<code: int, data: record, message: string>"
    append-text-using-get: "record<code: int, data: record, message: string>"
    append-text-using-post: "record<code: int, data: record, message: string>"
    check-token-using-get: "record<code: int, data: record, message: string>"
    check-token-using-post: "record<code: int, data: record, message: string>"
    copy-pad-using-get: "record<code: int, data: record, message: string>"
    copy-pad-using-post: "record<code: int, data: record, message: string>"
    copy-pad-without-history-using-get: "record<code: int, data: record, message: string>"
    copy-pad-without-history-using-post: "record<code: int, data: record, message: string>"
    create-author-using-get: "record<code: int, data: record<authorID: string>, message: string>"
    create-author-using-post: "record<code: int, data: record<authorID: string>, message: string>"
    create-author-if-not-exists-for-using-get: "record<code: int, data: record<authorID: string>, message: string>"
    create-author-if-not-exists-for-using-post: "record<code: int, data: record<authorID: string>, message: string>"
    create-diff-html-using-get: "record<code: int, data: record, message: string>"
    create-diff-html-using-post: "record<code: int, data: record, message: string>"
    create-group-using-get: "record<code: int, data: record<groupID: string>, message: string>"
    create-group-using-post: "record<code: int, data: record<groupID: string>, message: string>"
    create-group-if-not-exists-for-using-get: "record<code: int, data: record<groupID: string>, message: string>"
    create-group-if-not-exists-for-using-post: "record<code: int, data: record<groupID: string>, message: string>"
    create-group-pad-using-get: "record<code: int, data: record, message: string>"
    create-group-pad-using-post: "record<code: int, data: record, message: string>"
    create-pad-using-get: "record<code: int, data: record, message: string>"
    create-pad-using-post: "record<code: int, data: record, message: string>"
    create-session-using-get: "record<code: int, data: record<sessionID: string>, message: string>"
    create-session-using-post: "record<code: int, data: record<sessionID: string>, message: string>"
    delete-group-using-get: "record<code: int, data: record, message: string>"
    delete-group-using-post: "record<code: int, data: record, message: string>"
    delete-pad-using-get: "record<code: int, data: record, message: string>"
    delete-pad-using-post: "record<code: int, data: record, message: string>"
    delete-session-using-get: "record<code: int, data: record, message: string>"
    delete-session-using-post: "record<code: int, data: record, message: string>"
    get-attribute-pool-using-get: "record<code: int, data: record, message: string>"
    get-attribute-pool-using-post: "record<code: int, data: record, message: string>"
    get-author-name-using-get: "record<code: int, data: record<info: record<colorId: string, id: string, name: string, timestamp: int>>, message: string>"
    get-author-name-using-post: "record<code: int, data: record<info: record<colorId: string, id: string, name: string, timestamp: int>>, message: string>"
    get-chat-head-using-get: "record<code: int, data: record<chatHead: record<text: string, time: int, userId: string, userName: string>>, message: string>"
    get-chat-head-using-post: "record<code: int, data: record<chatHead: record<text: string, time: int, userId: string, userName: string>>, message: string>"
    get-chat-history-using-get: "record<code: int, data: record<messages: list<record>>, message: string>"
    get-chat-history-using-post: "record<code: int, data: record<messages: list<record>>, message: string>"
    get-html-using-get: "record<code: int, data: record<html: string>, message: string>"
    get-html-using-post: "record<code: int, data: record<html: string>, message: string>"
    get-last-edited-using-get: "record<code: int, data: record<lastEdited: int>, message: string>"
    get-last-edited-using-post: "record<code: int, data: record<lastEdited: int>, message: string>"
    get-pad-id-using-get: "record<code: int, data: record, message: string>"
    get-pad-id-using-post: "record<code: int, data: record, message: string>"
    get-public-status-using-get: "record<code: int, data: record<publicStatus: bool>, message: string>"
    get-public-status-using-post: "record<code: int, data: record<publicStatus: bool>, message: string>"
    get-read-only-id-using-get: "record<code: int, data: record<readOnlyID: string>, message: string>"
    get-read-only-id-using-post: "record<code: int, data: record<readOnlyID: string>, message: string>"
    get-revision-changeset-using-get: "record<code: int, data: record, message: string>"
    get-revision-changeset-using-post: "record<code: int, data: record, message: string>"
    get-revisions-count-using-get: "record<code: int, data: record<revisions: int>, message: string>"
    get-revisions-count-using-post: "record<code: int, data: record<revisions: int>, message: string>"
    get-saved-revisions-count-using-get: "record<code: int, data: record, message: string>"
    get-saved-revisions-count-using-post: "record<code: int, data: record, message: string>"
    get-session-info-using-get: "record<code: int, data: record<info: record<authorID: string, groupID: string, id: string, validUntil: int>>, message: string>"
    get-session-info-using-post: "record<code: int, data: record<info: record<authorID: string, groupID: string, id: string, validUntil: int>>, message: string>"
    get-stats-using-get: "record<code: int, data: record, message: string>"
    get-stats-using-post: "record<code: int, data: record, message: string>"
    get-text-using-get: "record<code: int, data: record<text: string>, message: string>"
    get-text-using-post: "record<code: int, data: record<text: string>, message: string>"
    list-all-groups-using-get: "record<code: int, data: record<groupIDs: list<string>>, message: string>"
    list-all-groups-using-post: "record<code: int, data: record<groupIDs: list<string>>, message: string>"
    list-all-pads-using-get: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-all-pads-using-post: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-authors-of-pad-using-get: "record<code: int, data: record<authorIDs: list<string>>, message: string>"
    list-authors-of-pad-using-post: "record<code: int, data: record<authorIDs: list<string>>, message: string>"
    list-pads-using-get: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-pads-using-post: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-pads-of-author-using-get: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-pads-of-author-using-post: "record<code: int, data: record<padIDs: list<string>>, message: string>"
    list-saved-revisions-using-get: "record<code: int, data: record, message: string>"
    list-saved-revisions-using-post: "record<code: int, data: record, message: string>"
    list-sessions-of-author-using-get: "record<code: int, data: record<sessions: list<record>>, message: string>"
    list-sessions-of-author-using-post: "record<code: int, data: record<sessions: list<record>>, message: string>"
    list-sessions-of-group-using-get: "record<code: int, data: record<sessions: list<record>>, message: string>"
    list-sessions-of-group-using-post: "record<code: int, data: record<sessions: list<record>>, message: string>"
    move-pad-using-get: "record<code: int, data: record, message: string>"
    move-pad-using-post: "record<code: int, data: record, message: string>"
    pad-users-using-get: "record<code: int, data: record<padUsers: list<record>>, message: string>"
    pad-users-using-post: "record<code: int, data: record<padUsers: list<record>>, message: string>"
    pad-users-count-using-get: "record<code: int, data: record<padUsersCount: int>, message: string>"
    pad-users-count-using-post: "record<code: int, data: record<padUsersCount: int>, message: string>"
    restore-revision-using-get: "record<code: int, data: record, message: string>"
    restore-revision-using-post: "record<code: int, data: record, message: string>"
    save-revision-using-get: "record<code: int, data: record, message: string>"
    save-revision-using-post: "record<code: int, data: record, message: string>"
    send-clients-message-using-get: "record<code: int, data: record, message: string>"
    send-clients-message-using-post: "record<code: int, data: record, message: string>"
    set-html-using-get: "record<code: int, data: record, message: string>"
    set-html-using-post: "record<code: int, data: record, message: string>"
    set-public-status-using-get: "record<code: int, data: record, message: string>"
    set-public-status-using-post: "record<code: int, data: record, message: string>"
    set-text-using-get: "record<code: int, data: record, message: string>"
    set-text-using-post: "record<code: int, data: record, message: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["append-chat-message-using-get" "append-chat-message-using-post" "append-text-using-get" "append-text-using-post" "check-token-using-get" "check-token-using-post" "copy-pad-using-get" "copy-pad-using-post" "copy-pad-without-history-using-get" "copy-pad-without-history-using-post" "create-author-using-get" "create-author-using-post" "create-author-if-not-exists-for-using-get" "create-author-if-not-exists-for-using-post" "create-diff-html-using-get" "create-diff-html-using-post" "create-group-using-get" "create-group-using-post" "create-group-if-not-exists-for-using-get" "create-group-if-not-exists-for-using-post" "create-group-pad-using-get" "create-group-pad-using-post" "create-pad-using-get" "create-pad-using-post" "create-session-using-get" "create-session-using-post" "delete-group-using-get" "delete-group-using-post" "delete-pad-using-get" "delete-pad-using-post" "delete-session-using-get" "delete-session-using-post" "get-attribute-pool-using-get" "get-attribute-pool-using-post" "get-author-name-using-get" "get-author-name-using-post" "get-chat-head-using-get" "get-chat-head-using-post" "get-chat-history-using-get" "get-chat-history-using-post" "get-html-using-get" "get-html-using-post" "get-last-edited-using-get" "get-last-edited-using-post" "get-pad-id-using-get" "get-pad-id-using-post" "get-public-status-using-get" "get-public-status-using-post" "get-read-only-id-using-get" "get-read-only-id-using-post" "get-revision-changeset-using-get" "get-revision-changeset-using-post" "get-revisions-count-using-get" "get-revisions-count-using-post" "get-saved-revisions-count-using-get" "get-saved-revisions-count-using-post" "get-session-info-using-get" "get-session-info-using-post" "get-stats-using-get" "get-stats-using-post" "get-text-using-get" "get-text-using-post" "list-all-groups-using-get" "list-all-groups-using-post" "list-all-pads-using-get" "list-all-pads-using-post" "list-authors-of-pad-using-get" "list-authors-of-pad-using-post" "list-pads-using-get" "list-pads-using-post" "list-pads-of-author-using-get" "list-pads-of-author-using-post" "list-saved-revisions-using-get" "list-saved-revisions-using-post" "list-sessions-of-author-using-get" "list-sessions-of-author-using-post" "list-sessions-of-group-using-get" "list-sessions-of-group-using-post" "move-pad-using-get" "move-pad-using-post" "pad-users-using-get" "pad-users-using-post" "pad-users-count-using-get" "pad-users-count-using-post" "restore-revision-using-get" "restore-revision-using-post" "save-revision-using-get" "save-revision-using-post" "send-clients-message-using-get" "send-clients-message-using-post" "set-html-using-get" "set-html-using-post" "set-public-status-using-get" "set-public-status-using-post" "set-text-using-get" "set-text-using-post" "commands"] | sort) } | get name | first)
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

# appends a chat message
#
# GET /appendChatMessage
# Returns: record<code: int, data: record, message: string>
# operationId: appendChatMessageUsingGET
export def "append-chat-message-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
  --author-id: string
  --time: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/appendChatMessage"
    query: [{name: padID, var: pad_id}, {name: text, var: text}, {name: authorID, var: author_id}, {name: time, var: time}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text, author_id: $author_id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# appends a chat message
#
# POST /appendChatMessage
# Returns: record<code: int, data: record, message: string>
# operationId: appendChatMessageUsingPOST
export def "append-chat-message-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
  --author-id: string
  --time: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/appendChatMessage"
    query: [{name: padID, var: pad_id}, {name: text, var: text}, {name: authorID, var: author_id}, {name: time, var: time}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text, author_id: $author_id, time: $time
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /appendText
#
# Returns: record<code: int, data: record, message: string>
# operationId: appendTextUsingGET
export def "append-text-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/appendText"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /appendText
#
# Returns: record<code: int, data: record, message: string>
# operationId: appendTextUsingPOST
export def "append-text-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/appendText"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns ok when the current api token is valid
#
# GET /checkToken
# Returns: record<code: int, data: record, message: string>
# operationId: checkTokenUsingGET
export def "check-token-using-get" [
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
    path: "/checkToken"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns ok when the current api token is valid
#
# POST /checkToken
# Returns: record<code: int, data: record, message: string>
# operationId: checkTokenUsingPOST
export def "check-token-using-post" [
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
    path: "/checkToken"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /copyPad
#
# Returns: record<code: int, data: record, message: string>
# operationId: copyPadUsingGET
export def "copy-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/copyPad"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /copyPad
#
# Returns: record<code: int, data: record, message: string>
# operationId: copyPadUsingPOST
export def "copy-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/copyPad"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /copyPadWithoutHistory
#
# Returns: record<code: int, data: record, message: string>
# operationId: copyPadWithoutHistoryUsingGET
export def "copy-pad-without-history-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/copyPadWithoutHistory"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /copyPadWithoutHistory
#
# Returns: record<code: int, data: record, message: string>
# operationId: copyPadWithoutHistoryUsingPOST
export def "copy-pad-without-history-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/copyPadWithoutHistory"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new author
#
# GET /createAuthor
# Returns: record<code: int, data: record<authorID: string>, message: string>
# operationId: createAuthorUsingGET
export def "create-author-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createAuthor"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new author
#
# POST /createAuthor
# Returns: record<code: int, data: record<authorID: string>, message: string>
# operationId: createAuthorUsingPOST
export def "create-author-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createAuthor"
    query: [{name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# this functions helps you to map your application author ids to Etherpad author ids
#
# GET /createAuthorIfNotExistsFor
# Returns: record<code: int, data: record<authorID: string>, message: string>
# operationId: createAuthorIfNotExistsForUsingGET
export def "create-author-if-not-exists-for-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-mapper: string
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createAuthorIfNotExistsFor"
    query: [{name: authorMapper, var: author_mapper}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_mapper: $author_mapper, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# this functions helps you to map your application author ids to Etherpad author ids
#
# POST /createAuthorIfNotExistsFor
# Returns: record<code: int, data: record<authorID: string>, message: string>
# operationId: createAuthorIfNotExistsForUsingPOST
export def "create-author-if-not-exists-for-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-mapper: string
  --name: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createAuthorIfNotExistsFor"
    query: [{name: authorMapper, var: author_mapper}, {name: name, var: name}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_mapper: $author_mapper, name: $name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /createDiffHTML
#
# Returns: record<code: int, data: record, message: string>
# operationId: createDiffHTMLUsingGET
export def "create-diff-html-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --start-rev: string
  --end-rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createDiffHTML"
    query: [{name: padID, var: pad_id}, {name: startRev, var: start_rev}, {name: endRev, var: end_rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, start_rev: $start_rev, end_rev: $end_rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /createDiffHTML
#
# Returns: record<code: int, data: record, message: string>
# operationId: createDiffHTMLUsingPOST
export def "create-diff-html-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --start-rev: string
  --end-rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createDiffHTML"
    query: [{name: padID, var: pad_id}, {name: startRev, var: start_rev}, {name: endRev, var: end_rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, start_rev: $start_rev, end_rev: $end_rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new group
#
# GET /createGroup
# Returns: record<code: int, data: record<groupID: string>, message: string>
# operationId: createGroupUsingGET
export def "create-group-using-get" [
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
    path: "/createGroup"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new group
#
# POST /createGroup
# Returns: record<code: int, data: record<groupID: string>, message: string>
# operationId: createGroupUsingPOST
export def "create-group-using-post" [
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
    path: "/createGroup"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# this functions helps you to map your application group ids to Etherpad group ids
#
# GET /createGroupIfNotExistsFor
# Returns: record<code: int, data: record<groupID: string>, message: string>
# operationId: createGroupIfNotExistsForUsingGET
export def "create-group-if-not-exists-for-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-mapper: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createGroupIfNotExistsFor"
    query: [{name: groupMapper, var: group_mapper}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_mapper: $group_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# this functions helps you to map your application group ids to Etherpad group ids
#
# POST /createGroupIfNotExistsFor
# Returns: record<code: int, data: record<groupID: string>, message: string>
# operationId: createGroupIfNotExistsForUsingPOST
export def "create-group-if-not-exists-for-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-mapper: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createGroupIfNotExistsFor"
    query: [{name: groupMapper, var: group_mapper}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_mapper: $group_mapper
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new pad in this group
#
# GET /createGroupPad
# Returns: record<code: int, data: record, message: string>
# operationId: createGroupPadUsingGET
export def "create-group-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
  --pad-name: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createGroupPad"
    query: [{name: groupID, var: group_id}, {name: padName, var: pad_name}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id, pad_name: $pad_name, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new pad in this group
#
# POST /createGroupPad
# Returns: record<code: int, data: record, message: string>
# operationId: createGroupPadUsingPOST
export def "create-group-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
  --pad-name: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createGroupPad"
    query: [{name: groupID, var: group_id}, {name: padName, var: pad_name}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id, pad_name: $pad_name, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new (non-group) pad. Note that if you need to create a group Pad, you should call createGroupPad
#
# GET /createPad
# Returns: record<code: int, data: record, message: string>
# operationId: createPadUsingGET
export def "create-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createPad"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new (non-group) pad. Note that if you need to create a group Pad, you should call createGroupPad
#
# POST /createPad
# Returns: record<code: int, data: record, message: string>
# operationId: createPadUsingPOST
export def "create-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createPad"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new session. validUntil is an unix timestamp in seconds
#
# GET /createSession
# Returns: record<code: int, data: record<sessionID: string>, message: string>
# operationId: createSessionUsingGET
export def "create-session-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
  --author-id: string
  --valid-until: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/createSession"
    query: [{name: groupID, var: group_id}, {name: authorID, var: author_id}, {name: validUntil, var: valid_until}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id, author_id: $author_id, valid_until: $valid_until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# creates a new session. validUntil is an unix timestamp in seconds
#
# POST /createSession
# Returns: record<code: int, data: record<sessionID: string>, message: string>
# operationId: createSessionUsingPOST
export def "create-session-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
  --author-id: string
  --valid-until: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/createSession"
    query: [{name: groupID, var: group_id}, {name: authorID, var: author_id}, {name: validUntil, var: valid_until}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id, author_id: $author_id, valid_until: $valid_until
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a group
#
# GET /deleteGroup
# Returns: record<code: int, data: record, message: string>
# operationId: deleteGroupUsingGET
export def "delete-group-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deleteGroup"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a group
#
# POST /deleteGroup
# Returns: record<code: int, data: record, message: string>
# operationId: deleteGroupUsingPOST
export def "delete-group-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/deleteGroup"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a pad
#
# GET /deletePad
# Returns: record<code: int, data: record, message: string>
# operationId: deletePadUsingGET
export def "delete-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deletePad"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a pad
#
# POST /deletePad
# Returns: record<code: int, data: record, message: string>
# operationId: deletePadUsingPOST
export def "delete-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/deletePad"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a session
#
# GET /deleteSession
# Returns: record<code: int, data: record, message: string>
# operationId: deleteSessionUsingGET
export def "delete-session-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --session-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/deleteSession"
    query: [{name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# deletes a session
#
# POST /deleteSession
# Returns: record<code: int, data: record, message: string>
# operationId: deleteSessionUsingPOST
export def "delete-session-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --session-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/deleteSession"
    query: [{name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /getAttributePool
#
# Returns: record<code: int, data: record, message: string>
# operationId: getAttributePoolUsingGET
export def "get-attribute-pool-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getAttributePool"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /getAttributePool
#
# Returns: record<code: int, data: record, message: string>
# operationId: getAttributePoolUsingPOST
export def "get-attribute-pool-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getAttributePool"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Author Name of the author
#
# GET /getAuthorName
# Returns: record<code: int, data: record<info: record<colorId: string, id: string, name: string, timestamp: int>>, message: string>
# operationId: getAuthorNameUsingGET
export def "get-author-name-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getAuthorName"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Returns the Author Name of the author
#
# POST /getAuthorName
# Returns: record<code: int, data: record<info: record<colorId: string, id: string, name: string, timestamp: int>>, message: string>
# operationId: getAuthorNameUsingPOST
export def "get-author-name-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getAuthorName"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the chatHead (chat-message) of the pad
#
# GET /getChatHead
# Returns: record<code: int, data: record<chatHead: record<text: string, time: int, userId: string, userName: string>>, message: string>
# operationId: getChatHeadUsingGET
export def "get-chat-head-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getChatHead"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the chatHead (chat-message) of the pad
#
# POST /getChatHead
# Returns: record<code: int, data: record<chatHead: record<text: string, time: int, userId: string, userName: string>>, message: string>
# operationId: getChatHeadUsingPOST
export def "get-chat-head-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getChatHead"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the chat history
#
# GET /getChatHistory
# Returns: record<code: int, data: record<messages: list<record>>, message: string>
# operationId: getChatHistoryUsingGET
export def "get-chat-history-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --start: string
  --end: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getChatHistory"
    query: [{name: padID, var: pad_id}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the chat history
#
# POST /getChatHistory
# Returns: record<code: int, data: record<messages: list<record>>, message: string>
# operationId: getChatHistoryUsingPOST
export def "get-chat-history-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --start: string
  --end: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getChatHistory"
    query: [{name: padID, var: pad_id}, {name: start, var: start}, {name: end, var: end}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, start: $start, end: $end
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the text of a pad formatted as HTML
#
# GET /getHTML
# Returns: record<code: int, data: record<html: string>, message: string>
# operationId: getHTMLUsingGET
export def "get-html-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getHTML"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the text of a pad formatted as HTML
#
# POST /getHTML
# Returns: record<code: int, data: record<html: string>, message: string>
# operationId: getHTMLUsingPOST
export def "get-html-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getHTML"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the timestamp of the last revision of the pad
#
# GET /getLastEdited
# Returns: record<code: int, data: record<lastEdited: int>, message: string>
# operationId: getLastEditedUsingGET
export def "get-last-edited-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getLastEdited"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the timestamp of the last revision of the pad
#
# POST /getLastEdited
# Returns: record<code: int, data: record<lastEdited: int>, message: string>
# operationId: getLastEditedUsingPOST
export def "get-last-edited-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getLastEdited"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /getPadID
#
# Returns: record<code: int, data: record, message: string>
# operationId: getPadIDUsingGET
export def "get-pad-id-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ro-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getPadID"
    query: [{name: roID, var: ro_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    ro_id: $ro_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /getPadID
#
# Returns: record<code: int, data: record, message: string>
# operationId: getPadIDUsingPOST
export def "get-pad-id-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ro-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getPadID"
    query: [{name: roID, var: ro_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    ro_id: $ro_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return true of false
#
# GET /getPublicStatus
# Returns: record<code: int, data: record<publicStatus: bool>, message: string>
# operationId: getPublicStatusUsingGET
export def "get-public-status-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getPublicStatus"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# return true of false
#
# POST /getPublicStatus
# Returns: record<code: int, data: record<publicStatus: bool>, message: string>
# operationId: getPublicStatusUsingPOST
export def "get-public-status-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getPublicStatus"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the read only link of a pad
#
# GET /getReadOnlyID
# Returns: record<code: int, data: record<readOnlyID: string>, message: string>
# operationId: getReadOnlyIDUsingGET
export def "get-read-only-id-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getReadOnlyID"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the read only link of a pad
#
# POST /getReadOnlyID
# Returns: record<code: int, data: record<readOnlyID: string>, message: string>
# operationId: getReadOnlyIDUsingPOST
export def "get-read-only-id-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getReadOnlyID"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /getRevisionChangeset
#
# Returns: record<code: int, data: record, message: string>
# operationId: getRevisionChangesetUsingGET
export def "get-revision-changeset-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getRevisionChangeset"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /getRevisionChangeset
#
# Returns: record<code: int, data: record, message: string>
# operationId: getRevisionChangesetUsingPOST
export def "get-revision-changeset-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getRevisionChangeset"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the number of revisions of this pad
#
# GET /getRevisionsCount
# Returns: record<code: int, data: record<revisions: int>, message: string>
# operationId: getRevisionsCountUsingGET
export def "get-revisions-count-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getRevisionsCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the number of revisions of this pad
#
# POST /getRevisionsCount
# Returns: record<code: int, data: record<revisions: int>, message: string>
# operationId: getRevisionsCountUsingPOST
export def "get-revisions-count-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getRevisionsCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /getSavedRevisionsCount
#
# Returns: record<code: int, data: record, message: string>
# operationId: getSavedRevisionsCountUsingGET
export def "get-saved-revisions-count-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getSavedRevisionsCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /getSavedRevisionsCount
#
# Returns: record<code: int, data: record, message: string>
# operationId: getSavedRevisionsCountUsingPOST
export def "get-saved-revisions-count-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getSavedRevisionsCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns informations about a session
#
# GET /getSessionInfo
# Returns: record<code: int, data: record<info: record<authorID: string, groupID: string, id: string, validUntil: int>>, message: string>
# operationId: getSessionInfoUsingGET
export def "get-session-info-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --session-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getSessionInfo"
    query: [{name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns informations about a session
#
# POST /getSessionInfo
# Returns: record<code: int, data: record<info: record<authorID: string, groupID: string, id: string, validUntil: int>>, message: string>
# operationId: getSessionInfoUsingPOST
export def "get-session-info-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --session-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getSessionInfo"
    query: [{name: sessionID, var: session_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    session_id: $session_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /getStats
#
# Returns: record<code: int, data: record, message: string>
# operationId: getStatsUsingGET
export def "get-stats-using-get" [
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
    path: "/getStats"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /getStats
#
# Returns: record<code: int, data: record, message: string>
# operationId: getStatsUsingPOST
export def "get-stats-using-post" [
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
    path: "/getStats"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the text of a pad
#
# GET /getText
# Returns: record<code: int, data: record<text: string>, message: string>
# operationId: getTextUsingGET
export def "get-text-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/getText"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the text of a pad
#
# POST /getText
# Returns: record<code: int, data: record<text: string>, message: string>
# operationId: getTextUsingPOST
export def "get-text-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/getText"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /listAllGroups
#
# Returns: record<code: int, data: record<groupIDs: list<string>>, message: string>
# operationId: listAllGroupsUsingGET
export def "list-all-groups-using-get" [
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
    path: "/listAllGroups"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /listAllGroups
#
# Returns: record<code: int, data: record<groupIDs: list<string>>, message: string>
# operationId: listAllGroupsUsingPOST
export def "list-all-groups-using-post" [
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
    path: "/listAllGroups"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list all the pads
#
# GET /listAllPads
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listAllPadsUsingGET
export def "list-all-pads-using-get" [
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
    path: "/listAllPads"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# list all the pads
#
# POST /listAllPads
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listAllPadsUsingPOST
export def "list-all-pads-using-post" [
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
    path: "/listAllPads"
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns an array of authors who contributed to this pad
#
# GET /listAuthorsOfPad
# Returns: record<code: int, data: record<authorIDs: list<string>>, message: string>
# operationId: listAuthorsOfPadUsingGET
export def "list-authors-of-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listAuthorsOfPad"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns an array of authors who contributed to this pad
#
# POST /listAuthorsOfPad
# Returns: record<code: int, data: record<authorIDs: list<string>>, message: string>
# operationId: listAuthorsOfPadUsingPOST
export def "list-authors-of-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listAuthorsOfPad"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns all pads of this group
#
# GET /listPads
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listPadsUsingGET
export def "list-pads-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listPads"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns all pads of this group
#
# POST /listPads
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listPadsUsingPOST
export def "list-pads-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listPads"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns an array of all pads this author contributed to
#
# GET /listPadsOfAuthor
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listPadsOfAuthorUsingGET
export def "list-pads-of-author-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listPadsOfAuthor"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns an array of all pads this author contributed to
#
# POST /listPadsOfAuthor
# Returns: record<code: int, data: record<padIDs: list<string>>, message: string>
# operationId: listPadsOfAuthorUsingPOST
export def "list-pads-of-author-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listPadsOfAuthor"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /listSavedRevisions
#
# Returns: record<code: int, data: record, message: string>
# operationId: listSavedRevisionsUsingGET
export def "list-saved-revisions-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listSavedRevisions"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /listSavedRevisions
#
# Returns: record<code: int, data: record, message: string>
# operationId: listSavedRevisionsUsingPOST
export def "list-saved-revisions-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listSavedRevisions"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns all sessions of an author
#
# GET /listSessionsOfAuthor
# Returns: record<code: int, data: record<sessions: list<record>>, message: string>
# operationId: listSessionsOfAuthorUsingGET
export def "list-sessions-of-author-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listSessionsOfAuthor"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns all sessions of an author
#
# POST /listSessionsOfAuthor
# Returns: record<code: int, data: record<sessions: list<record>>, message: string>
# operationId: listSessionsOfAuthorUsingPOST
export def "list-sessions-of-author-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listSessionsOfAuthor"
    query: [{name: authorID, var: author_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    author_id: $author_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /listSessionsOfGroup
#
# Returns: record<code: int, data: record<sessions: list<record>>, message: string>
# operationId: listSessionsOfGroupUsingGET
export def "list-sessions-of-group-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/listSessionsOfGroup"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /listSessionsOfGroup
#
# Returns: record<code: int, data: record<sessions: list<record>>, message: string>
# operationId: listSessionsOfGroupUsingPOST
export def "list-sessions-of-group-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/listSessionsOfGroup"
    query: [{name: groupID, var: group_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    group_id: $group_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /movePad
#
# Returns: record<code: int, data: record, message: string>
# operationId: movePadUsingGET
export def "move-pad-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/movePad"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /movePad
#
# Returns: record<code: int, data: record, message: string>
# operationId: movePadUsingPOST
export def "move-pad-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-id: string
  --destination-id: string
  --force: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/movePad"
    query: [{name: sourceID, var: source_id}, {name: destinationID, var: destination_id}, {name: force, var: force}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    source_id: $source_id, destination_id: $destination_id, force: $force
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the list of users that are currently editing this pad
#
# GET /padUsers
# Returns: record<code: int, data: record<padUsers: list<record>>, message: string>
# operationId: padUsersUsingGET
export def "pad-users-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/padUsers"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the list of users that are currently editing this pad
#
# POST /padUsers
# Returns: record<code: int, data: record<padUsers: list<record>>, message: string>
# operationId: padUsersUsingPOST
export def "pad-users-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/padUsers"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the number of user that are currently editing this pad
#
# GET /padUsersCount
# Returns: record<code: int, data: record<padUsersCount: int>, message: string>
# operationId: padUsersCountUsingGET
export def "pad-users-count-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/padUsersCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# returns the number of user that are currently editing this pad
#
# POST /padUsersCount
# Returns: record<code: int, data: record<padUsersCount: int>, message: string>
# operationId: padUsersCountUsingPOST
export def "pad-users-count-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/padUsersCount"
    query: [{name: padID, var: pad_id}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /restoreRevision
#
# Returns: record<code: int, data: record, message: string>
# operationId: restoreRevisionUsingGET
export def "restore-revision-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/restoreRevision"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /restoreRevision
#
# Returns: record<code: int, data: record, message: string>
# operationId: restoreRevisionUsingPOST
export def "restore-revision-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/restoreRevision"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# GET /saveRevision
#
# Returns: record<code: int, data: record, message: string>
# operationId: saveRevisionUsingGET
export def "save-revision-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/saveRevision"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# POST /saveRevision
#
# Returns: record<code: int, data: record, message: string>
# operationId: saveRevisionUsingPOST
export def "save-revision-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --rev: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/saveRevision"
    query: [{name: padID, var: pad_id}, {name: rev, var: rev}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, rev: $rev
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sends a custom message of type msg to the pad
#
# GET /sendClientsMessage
# Returns: record<code: int, data: record, message: string>
# operationId: sendClientsMessageUsingGET
export def "send-clients-message-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --msg: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/sendClientsMessage"
    query: [{name: padID, var: pad_id}, {name: msg, var: msg}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, msg: $msg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sends a custom message of type msg to the pad
#
# POST /sendClientsMessage
# Returns: record<code: int, data: record, message: string>
# operationId: sendClientsMessageUsingPOST
export def "send-clients-message-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --msg: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/sendClientsMessage"
    query: [{name: padID, var: pad_id}, {name: msg, var: msg}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, msg: $msg
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets the text of a pad with HTML
#
# GET /setHTML
# Returns: record<code: int, data: record, message: string>
# operationId: setHTMLUsingGET
export def "set-html-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --html: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setHTML"
    query: [{name: padID, var: pad_id}, {name: html, var: html}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, html: $html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets the text of a pad with HTML
#
# POST /setHTML
# Returns: record<code: int, data: record, message: string>
# operationId: setHTMLUsingPOST
export def "set-html-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --html: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/setHTML"
    query: [{name: padID, var: pad_id}, {name: html, var: html}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, html: $html
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets a boolean for the public status of a pad
#
# GET /setPublicStatus
# Returns: record<code: int, data: record, message: string>
# operationId: setPublicStatusUsingGET
export def "set-public-status-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --public-status: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setPublicStatus"
    query: [{name: padID, var: pad_id}, {name: publicStatus, var: public_status}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, public_status: $public_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets a boolean for the public status of a pad
#
# POST /setPublicStatus
# Returns: record<code: int, data: record, message: string>
# operationId: setPublicStatusUsingPOST
export def "set-public-status-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --public-status: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/setPublicStatus"
    query: [{name: padID, var: pad_id}, {name: publicStatus, var: public_status}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, public_status: $public_status
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets the text of a pad
#
# GET /setText
# Returns: record<code: int, data: record, message: string>
# operationId: setTextUsingGET
export def "set-text-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/setText"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# sets the text of a pad
#
# POST /setText
# Returns: record<code: int, data: record, message: string>
# operationId: setTextUsingPOST
export def "set-text-using-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pad-id: string
  --text: string
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: post
    path: "/setText"
    query: [{name: padID, var: pad_id}, {name: text, var: text}]
    accept: ["application/json"]
    ok: [200]
    auth: query-apikey
  } {
    pad_id: $pad_id, text: $text
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
