# Auto-generated client for uebermaps API endpoints v2.0
# Source: https://api.apis.guru/v2/specs/uebermaps.com/2.0/swagger.json
# Auth: --token flag or $env.UEBERMAPS_API_ENDPOINTS_TOKEN

const CLIENT = {
  base_url: "https://uebermaps.com/api/v2"
  token_env_var: "UEBERMAPS_API_ENDPOINTS_TOKEN"
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

def base-url-completer [] { ["https://uebermaps.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def visibility-completer [] { ["link" "private" "public"] }
def group-completer [] { ["admin" "editor"] }
def order-completer [] { ["created_at_asc" "created_at_desc" "title_asc" "title_desc" "updated_at_asc" "updated_at_desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    patch-account: "record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>"
    delete-attachments-id: "record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-authentication: "record<auth_token: string, language: string, time_zone: string, about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>"
    get-collaborator-invitations: "table<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-collaborator-invitations: "record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-collaborator-invitations-id: "record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-collaborator-invitations-id: "record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    patch-collaborator-invitations-id: "record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-comments-id: "record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    patch-comments-id: "record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-events: "table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-events-id: "record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-events-id: "record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    patch-events-id: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-maps: "table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    post-maps: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-maps-search: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    delete-maps-id: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-maps-id: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, relation: record<access: string, access_group: string, subscribed: bool>, title: string, updated_at: string, visibility: string>"
    patch-maps-id: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-maps-id-attachments: "table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-maps-id-attachments: "record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-maps-id-collaborators: "table<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    delete-maps-id-collaborators-user-id: "record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    patch-maps-id-collaborators-user-id: "record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    get-maps-id-comments: "table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-maps-id-comments: "record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-maps-id-respots: "table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-maps-id-spots: "table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-maps-id-spots: "record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-maps-id-subscriptions: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    get-maps-id-subscriptions: "table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    get-maps-map-id-spots-id: "record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-maps-map-id-spots-spot-id-respot: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-respot-maps: "table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    delete-respots-id: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-respots-id: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-share-map-id: "record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, owner_id: int, picture_url: string, title: string, token: string, updated_at: string, visibility: string>"
    get-spots: "table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-spots-search: "record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    delete-spots-id: "record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    patch-spots-id: "record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-spots-id-attachments: "table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-spots-id-attachments: "record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-spots-id-comments: "table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-spots-id-comments: "record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-spots-id-events: "table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-spots-id-events: "record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    post-spots-id-respots: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>"
    get-subscriptions: "table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    post-subscriptions: "record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>"
    get-trends-latest: "table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-trends-recommended: "table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
    get-users-search: "record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>"
    get-users-id: "record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>"
    get-users-user-id-maps: "table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["patch-account" "delete-attachments-id" "post-authentication" "get-collaborator-invitations" "post-collaborator-invitations" "delete-collaborator-invitations-id" "get-collaborator-invitations-id" "patch-collaborator-invitations-id" "delete-comments-id" "patch-comments-id" "get-events" "delete-events-id" "get-events-id" "patch-events-id" "get-maps" "post-maps" "get-maps-search" "delete-maps-id" "get-maps-id" "patch-maps-id" "get-maps-id-attachments" "post-maps-id-attachments" "get-maps-id-collaborators" "delete-maps-id-collaborators-user-id" "patch-maps-id-collaborators-user-id" "get-maps-id-comments" "post-maps-id-comments" "get-maps-id-respots" "get-maps-id-spots" "post-maps-id-spots" "delete-maps-id-subscriptions" "get-maps-id-subscriptions" "get-maps-map-id-spots-id" "delete-maps-map-id-spots-spot-id-respot" "get-respot-maps" "delete-respots-id" "get-respots-id" "get-share-map-id" "get-spots" "get-spots-search" "delete-spots-id" "patch-spots-id" "get-spots-id-attachments" "post-spots-id-attachments" "get-spots-id-comments" "post-spots-id-comments" "get-spots-id-events" "post-spots-id-events" "post-spots-id-respots" "get-subscriptions" "post-subscriptions" "get-trends-latest" "get-trends-recommended" "get-users-search" "get-users-id" "get-users-user-id-maps" "commands"] | sort) } | get name | first)
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

# Update account
#
# PATCH /account
# Returns: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>
export def "patch-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --about: string # e.g. The comedian
  --header: string # e.g. <BASE_64_ENCODED_STRING>
  --language: string # e.g. en
  --location: string # e.g. Little Rock, Arkansas
  --name: string # e.g. Bill Hicks
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --screen-name: string # e.g. billhicks
  --time-zone: string # e.g. Pacific Time (US & Canada)
  --url: string # e.g. http://www.billhicks.com
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/account"
    body: {content_type: "application/json", kind: json, fields: [{name: about, var: about}, {name: header, var: header}, {name: language, var: language}, {name: location, var: location}, {name: name, var: name}, {name: picture, var: picture}, {name: screen_name, var: screen_name}, {name: time_zone, var: time_zone}, {name: url, var: url}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    about: $about, header: $header, language: $language, location: $location, name: $name, picture: $picture, screen_name: $screen_name, time_zone: $time_zone, url: $url
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete attachment
#
# DELETE /attachments/{id}
# Returns: record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-attachments-id" [
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
    path: "/attachments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Sign in user
#
# POST /authentication
# Returns: record<auth_token: string, language: string, time_zone: string, about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>
export def "post-authentication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. a@b.com
  --password: string # e.g. ••••••••
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/authentication"
    body: {content_type: "application/json", kind: json, fields: [{name: email, var: email}, {name: password, var: password}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    email: $email, password: $password
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List your collaborator invitations
#
# GET /collaborator_invitations
# Returns: table<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-collaborator-invitations" [
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
    path: "/collaborator_invitations"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Invite user to collaborate on map
#
# POST /collaborator_invitations
# Returns: record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-collaborator-invitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: string # e.g. a@b.com, c@d.com, e@f.com
  --is-admin: oneof<nothing, bool> # e.g. true
  --map-id: int # e.g. 34925783
  --user-ids: string # e.g. 5839459, 389423, 89494, 686950
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/collaborator_invitations"
    body: {content_type: "application/json", kind: json, fields: [{name: emails, var: emails}, {name: is_admin, var: is_admin}, {name: map_id, var: map_id}, {name: user_ids, var: user_ids}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    emails: $emails, is_admin: $is_admin, map_id: $map_id, user_ids: $user_ids
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collaborator invitation
#
# DELETE /collaborator_invitations/{id}
# Returns: record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-collaborator-invitations-id" [
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
    path: "/collaborator_invitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Show collaborator invitation
#
# GET /collaborator_invitations/{id}
# Returns: record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-collaborator-invitations-id" [
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
    path: "/collaborator_invitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Accept collaborator invitation.
#
# PATCH /collaborator_invitations/{id}
# Returns: record<accepted: bool, created_at: string, email: string, group: string, id: int, invited_by_user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, sent: bool, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "patch-collaborator-invitations-id" [
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
    method: patch
    path: "/collaborator_invitations/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete comment
#
# DELETE /comments/{id}
# Returns: record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-comments-id" [
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
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update comment
#
# PATCH /comments/{id}
# Returns: record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "patch-comments-id" [
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
  --body: string # e.g. Nice photo
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/comments/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List your own events
#
# GET /events
# Returns: table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeframe-start: string # Begin of time range of event (ISO 8601 date format).
  --timeframe-end: string # End of time range of event (ISO 8601 date format).
  --bounds: string # To refine your event index request to contain only events within a geographical box pass the followng bounds parameters. F. e. to get events within 'Hamburg, St. Pauli': bounds[sw_lat]=53.54831449741324 bounds[sw_lon]=9.943227767944336 bounds[ne_lat]=53.5571103674878 bounds[ne_lon]=9.9776029586792
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/events"
    query: [{name: timeframe_start, var: timeframe_start}, {name: timeframe_end, var: timeframe_end}, {name: bounds, var: bounds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    timeframe_start: $timeframe_start, timeframe_end: $timeframe_end, bounds: $bounds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete event
#
# DELETE /events/{id}
# Returns: record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-events-id" [
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
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get event
#
# GET /events/{id}
# Returns: record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-events-id" [
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
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update event
#
# PATCH /events/{id}
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "patch-events-id" [
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
  --description: string # e.g. Very special event
  --ends-at: string # format: date-time
  --lat: float # e.g. 53.293493
  --lon: float # e.g. 12.394328
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --starts-at: string # format: date-time
  --time-zone: string # e.g. Berlin
  --title: string # e.g. 20th anniversary event
  --user-id: int # e.g. 703943
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/events/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: ends_at, var: ends_at}, {name: lat, var: lat}, {name: lon, var: lon}, {name: picture, var: picture}, {name: starts_at, var: starts_at}, {name: time_zone, var: time_zone}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, ends_at: $ends_at, lat: $lat, lon: $lon, picture: $picture, starts_at: $starts_at, time_zone: $time_zone, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List your own maps
#
# GET /maps
# Returns: table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-maps" [
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
    path: "/maps"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create map
#
# POST /maps
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "post-maps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # e.g. A collection of restaurants, cafes, clubs and random spots that I recommend in Berlin
  --map-settings: any # shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --title: string # e.g. My favourite places in Berlin
  --visibility: string@visibility-completer # e.g. public
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps"
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: map_settings, var: map_settings}, {name: picture, var: picture}, {name: title, var: title}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    description: $description, map_settings: $map_settings, picture: $picture, title: $title, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search maps
#
# GET /maps/search
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-maps-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
  --d: int # Distance. Diameter of search radius in meter (default: 2000 meter)
  --lat: float # Latitude for search radius (default distance: 2000 meter)
  --lon: float # Longitude for search radius (default distance: 2000 meter)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/maps/search"
    query: [{name: q, var: q}, {name: d, var: d}, {name: lat, var: lat}, {name: lon, var: lon}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, d: $d, lat: $lat, lon: $lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete map
#
# DELETE /maps/{id}
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "delete-maps-id" [
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
    path: "/maps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get map
#
# GET /maps/{id}
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, relation: record<access: string, access_group: string, subscribed: bool>, title: string, updated_at: string, visibility: string>
export def "get-maps-id" [
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
    path: "/maps/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update map
#
# PATCH /maps/{id}
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "patch-maps-id" [
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
  --description: string # e.g. A collection of restaurants, cafes, clubs and random spots that I recommend in Berlin
  --map-settings: any # shape: {editor_access?: string, respotting_to_this_map?: bool, visitor_access?: string}
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --title: string # e.g. My favourite places in Berlin
  --visibility: string@visibility-completer # e.g. public
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/maps/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: map_settings, var: map_settings}, {name: picture, var: picture}, {name: title, var: title}, {name: visibility, var: visibility}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, map_settings: $map_settings, picture: $picture, title: $title, visibility: $visibility
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments for a given map
#
# GET /maps/{id}/attachments
# Returns: table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-maps-id-attachments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/attachments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload map attachment
#
# POST /maps/{id}/attachments
# Returns: record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-maps-id-attachments" [
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
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps/{id}/attachments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List collaborators of a map
#
# GET /maps/{id}/collaborators/
# Returns: table<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "get-maps-id-collaborators" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/collaborators/"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete collaboration
#
# DELETE /maps/{id}/collaborators/{user_id}
# Returns: record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "delete-maps-id-collaborators-user-id" [
  id: int
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
    method: delete
    path: "/maps/{id}/collaborators/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update collaborator
#
# PATCH /maps/{id}/collaborators/{user_id}
# Returns: record<created_at: string, group: string, id: int, is_admin: bool, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "patch-maps-id-collaborators-user-id" [
  id: int
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
  --group: string@group-completer # e.g. editor
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/maps/{id}/collaborators/{user_id}"
    path_params: [{name: id, var: id}, {name: user_id, var: user_id}]
    body: {content_type: "application/json", kind: json, fields: [{name: group, var: group}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, user_id: $user_id, group: $group
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List comments for a given map
#
# GET /maps/{id}/comments
# Returns: table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-maps-id-comments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create map comment
#
# POST /maps/{id}/comments
# Returns: record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-maps-id-comments" [
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
  --body: string # e.g. Nice photo
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List respots of a map
#
# GET /maps/{id}/respots
# Returns: table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-maps-id-respots" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/respots"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List spots for a given map
#
# GET /maps/{id}/spots
# Returns: table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-maps-id-spots" [
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
  --order: string@order-completer # Order of spots
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/spots"
    path_params: [{name: id, var: id}]
    query: [{name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create spot
#
# POST /maps/{id}/spots
# Returns: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-maps-id-spots" [
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
  --description: string # e.g. Landed here by accident but look how wonderful this place is in the photos attached
  --lat: float # e.g. 53.112385
  --lon: float # e.g. 10.58349
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --time-zone: string # e.g. Berlin
  --title: string # e.g. Beautiful place out in the country
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/maps/{id}/spots"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: lat, var: lat}, {name: lon, var: lon}, {name: picture, var: picture}, {name: time_zone, var: time_zone}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, lat: $lat, lon: $lon, picture: $picture, time_zone: $time_zone, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Unsubscribe from map
#
# DELETE /maps/{id}/subscriptions
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "delete-maps-id-subscriptions" [
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
    path: "/maps/{id}/subscriptions"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List subscriptions for a given map
#
# GET /maps/{id}/subscriptions
# Returns: table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "get-maps-id-subscriptions" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/maps/{id}/subscriptions"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get spot
#
# GET /maps/{map_id}/spots/{id}
# Returns: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-maps-map-id-spots-id" [
  map_id: int
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
    path: "/maps/{map_id}/spots/{id}"
    path_params: [{name: map_id, var: map_id}, {name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_id: $map_id, id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete respot from map by spot id
#
# DELETE /maps/{map_id}/spots/{spot_id}/respot
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-maps-map-id-spots-spot-id-respot" [
  map_id: int
  spot_id: int
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
    path: "/maps/{map_id}/spots/{spot_id}/respot"
    path_params: [{name: map_id, var: map_id}, {name: spot_id, var: spot_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    map_id: $map_id, spot_id: $spot_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List maps that user can respot to
#
# GET /respot_maps
# Returns: table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-respot-maps" [
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
    path: "/respot_maps"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete respot
#
# DELETE /respots/{id}
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-respots-id" [
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
    path: "/respots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get respot
#
# GET /respots/{id}
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-respots-id" [
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
    path: "/respots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get secret access token to share map
#
# GET /share/map/{id}
# Returns: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, owner_id: int, picture_url: string, title: string, token: string, updated_at: string, visibility: string>
export def "get-share-map-id" [
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
    path: "/share/map/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List your own spots
#
# GET /spots
# Returns: table<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-spots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # Order of spots
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spots"
    query: [{name: order, var: order}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    order: $order
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search spots
#
# GET /spots/search
# Returns: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-spots-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
  --d: int # Distance. Diameter of search radius in meter (default: 2000 meter)
  --lat: float # Latitude for search radius (2 km)
  --lon: float # Longitude for search radius (2 km)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/spots/search"
    query: [{name: q, var: q}, {name: d, var: d}, {name: lat, var: lat}, {name: lon, var: lon}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, d: $d, lat: $lat, lon: $lon
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete spot
#
# DELETE /spots/{id}
# Returns: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "delete-spots-id" [
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
    path: "/spots/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update spot
#
# PATCH /spots/{id}
# Returns: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "patch-spots-id" [
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
  --description: string # e.g. Landed here by accident but look how wonderful this place is in the photos attached
  --lat: float # e.g. 53.112385
  --lon: float # e.g. 10.58349
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --time-zone: string # e.g. Berlin
  --title: string # e.g. Beautiful place out in the country
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/spots/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: lat, var: lat}, {name: lon, var: lon}, {name: picture, var: picture}, {name: time_zone, var: time_zone}, {name: title, var: title}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, lat: $lat, lon: $lon, picture: $picture, time_zone: $time_zone, title: $title
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List attachments for a given spot
#
# GET /spots/{id}/attachments
# Returns: table<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, status: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-spots-id-attachments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spots/{id}/attachments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upload spot attachment
#
# POST /spots/{id}/attachments
# Returns: record<attachable_id: int, attachable_type: string, created_at: string, description: string, file_url: string, id: int, map_id: int, sizes: record, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, status: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-spots-id-attachments" [
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
  --body: string
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spots/{id}/attachments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List comments for a given spot
#
# GET /spots/{id}/comments
# Returns: table<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-spots-id-comments" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spots/{id}/comments"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create spot comment
#
# POST /spots/{id}/comments
# Returns: record<body: string, created_at: string, id: int, status: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-spots-id-comments" [
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
  --body: string # e.g. Nice photo
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spots/{id}/comments"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: body, var: body}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List events for a given spot
#
# GET /spots/{id}/events
# Returns: table<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "get-spots-id-events" [
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
  --timeframe-start: string # Begin of time range of event (ISO 8601 date format).
  --timeframe-end: string # End of time range of event (ISO 8601 date format).
  --bounds: string # To refine your event index request to contain only events within a geographical box pass the followng bounds parameters. F. e. to get events within 'Hamburg, St. Pauli': bounds[sw_lat]=53.54831449741324 bounds[sw_lon]=9.943227767944336 bounds[ne_lat]=53.5571103674878 bounds[ne_lon]=9.9776029586792
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/spots/{id}/events"
    path_params: [{name: id, var: id}]
    query: [{name: timeframe_start, var: timeframe_start}, {name: timeframe_end, var: timeframe_end}, {name: bounds, var: bounds}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, timeframe_start: $timeframe_start, timeframe_end: $timeframe_end, bounds: $bounds
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create event
#
# POST /spots/{id}/events
# Returns: record<counts: record<attachments: int, comments: int>, created_at: string, description: string, ends_at: string, id: int, lat: float, lon: float, owner_id: int, picture_url: string, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, starts_at: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-spots-id-events" [
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
  --description: string # e.g. Very special event
  --ends-at: string # format: date-time
  --lat: float # e.g. 53.293493
  --lon: float # e.g. 12.394328
  --picture: string # e.g. <BASE_64_ENCODED_STRING>
  --starts-at: string # format: date-time
  --time-zone: string # e.g. Berlin
  --title: string # e.g. 20th anniversary event
  --user-id: int # e.g. 703943
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spots/{id}/events"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, fields: [{name: description, var: description}, {name: ends_at, var: ends_at}, {name: lat, var: lat}, {name: lon, var: lon}, {name: picture, var: picture}, {name: starts_at, var: starts_at}, {name: time_zone, var: time_zone}, {name: title, var: title}, {name: user_id, var: user_id}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, description: $description, ends_at: $ends_at, lat: $lat, lon: $lon, picture: $picture, starts_at: $starts_at, time_zone: $time_zone, title: $title, user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Respot a spot onto a map
#
# POST /spots/{id}/respots
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, map_id: int, spot: record<counts: record<attachments: int, comments: int, respot: int>, created_at: string, description: string, id: int, lat: float, lon: float, map_id: int, picture_url: string, status: string, time_zone: string, title: string, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>>
export def "post-spots-id-respots" [
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
  --body: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/spots/{id}/respots"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List subscriptions. Pass no parameters to get own subscriptions
#
# GET /subscriptions
# Returns: table<created_at: string, id: int, map: record<counts: record, created_at: string, description: string, id: int, map_settings: record, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Id of user
  --map-id: int # Id of map
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/subscriptions"
    query: [{name: user_id, var: user_id}, {name: map_id, var: map_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id, map_id: $map_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create map subscription
#
# POST /subscriptions
# Returns: record<created_at: string, id: int, map: record<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>, updated_at: string, user: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>, user_id: int>
export def "post-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: float
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/subscriptions"
    body: {content_type: "application/json", kind: json, accepts: scalar}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    body: $body
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List latest maps
#
# GET /trends/latest
# Returns: table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-trends-latest" [
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
    path: "/trends/latest"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List recommended maps
#
# GET /trends/recommended
# Returns: table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-trends-recommended" [
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
    path: "/trends/recommended"
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Search users
#
# GET /users/search
# Returns: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>
export def "get-users-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/users/search"
    query: [{name: q, var: q}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get user profile
#
# GET /users/{id}
# Returns: record<about: string, counts: record<maps: int>, header_picture: string, id: int, location: string, name: string, picture_url: string, screen_name: string, url: string>
export def "get-users-id" [
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
    path: "/users/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List maps for a given user
#
# GET /users/{user_id}/maps
# Returns: table<counts: record<attachments: int, comments: int, impressions: int, respots: int, spots: int, subscriptions: int>, created_at: string, description: string, id: int, map_settings: record<editor_access: string, respotting_to_this_map: bool, visitor_access: string>, owner_id: int, picture_url: string, title: string, updated_at: string, visibility: string>
export def "get-users-user-id-maps" [
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
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/users/{user_id}/maps"
    path_params: [{name: user_id, var: user_id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    user_id: $user_id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
