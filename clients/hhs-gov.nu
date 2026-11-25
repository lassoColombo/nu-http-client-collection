# Auto-generated client for HHS Media Services API v2
# Source: https://api.apis.guru/v2/specs/hhs.gov/2/openapi.json
# Auth: --token flag or $env.HHS_MEDIA_SERVICES_API_TOKEN

const CLIENT = {
  base_url: "https://api.apis.guru/api/v2"
  token_env_var: "HHS_MEDIA_SERVICES_API_TOKEN"
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

def base-url-completer [] { ["https://api.apis.guru/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    get-resources-json: "list<any>"
    get-resources-campaigns-json: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>>"
    get-resources-campaigns-id-json: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>>"
    get-resources-campaigns-id-media-json: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<campaigns: list, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record, mediaType: string, name: string, source: record, sourceUrl: string, targetUrl: string>>"
    get-resources-campaigns-id-syndicate-format: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>>"
    get-resources-languages-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-languages-id-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-featured-json: "table<campaigns: list<record>, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list<record>, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record<id: int, isActive: bool, isoCode: string, name: string>, mediaType: string, name: string, source: record<acronym: string, contactEmail: string, id: int, largeLogoUrl: string, name: string, smallLogoUrl: string, websiteUrl: string>, sourceUrl: string, targetUrl: string>"
    get-resources-media-most-popular-media-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-search-results-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-id-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-id-content: "string"
    get-resources-media-id-embed-json: "string"
    get-resources-media-id-preview-jpg: "record"
    get-resources-media-id-related-media-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-media-id-syndicate-format: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>>"
    get-resources-media-id-thumbnail-jpg: "record"
    get-resources-media-id-youtube-meta-data-json: "record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: list<record>>"
    get-resources-media-types-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-sources-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-sources-id-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-sources-id-syndicate-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-tag-languages-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-tag-types-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-id-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-id-media-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-id-related-format: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
    get-resources-tags-id-syndicate-format: "string"
    get-resources-user-media-lists-id-json: "table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-resources-json" "get-resources-campaigns-json" "get-resources-campaigns-id-json" "get-resources-campaigns-id-media-json" "get-resources-campaigns-id-syndicate-format" "get-resources-languages-json" "get-resources-languages-id-json" "get-resources-media-json" "get-resources-media-featured-json" "get-resources-media-most-popular-media-format" "get-resources-media-search-results-json" "get-resources-media-id-json" "get-resources-media-id-content" "get-resources-media-id-embed-json" "get-resources-media-id-preview-jpg" "get-resources-media-id-related-media-format" "get-resources-media-id-syndicate-format" "get-resources-media-id-thumbnail-jpg" "get-resources-media-id-youtube-meta-data-json" "get-resources-media-types-format" "get-resources-sources-json" "get-resources-sources-id-json" "get-resources-sources-id-syndicate-format" "get-resources-tags-format" "get-resources-tags-tag-languages-format" "get-resources-tags-tag-types-format" "get-resources-tags-id-format" "get-resources-tags-id-media-format" "get-resources-tags-id-related-format" "get-resources-tags-id-syndicate-format" "get-resources-user-media-lists-id-json" "commands"] | sort) } | get name | first)
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

# Get Resources by search query
#
# GET /resources.json
# Returns: list<any>
export def "get-resources-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query supplied by the user (required, format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources.json"
    query: [{name: q, var: q, required: true}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Campaigns
#
# GET /resources/campaigns.json
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>>
export def "get-resources-campaigns-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination (format: int32)
  --sort: string # * Set of fields to sort the records by. (format: )
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/campaigns.json"
    query: [{name: max, var: max}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max: $max, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Campaign by ID
#
# GET /resources/campaigns/{id}.json
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>>
export def "get-resources-campaigns-id-json" [
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
    path: "/resources/campaigns/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems by Campaign ID
#
# GET /resources/campaigns/{id}/media.json
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<campaigns: list, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record, mediaType: string, name: string, source: record, sourceUrl: string, targetUrl: string>>
export def "get-resources-campaigns-id-media-json" [
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
  --sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination (format: int32)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/campaigns/{id}/media.json"
    path_params: [{name: id, var: id}]
    query: [{name: sort, var: sort}, {name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, sort: $sort, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems for Campaign
#
# GET /resources/campaigns/{id}/syndicate.{format}
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>>
export def "get-resources-campaigns-id-syndicate-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/campaigns/{id}/syndicate.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: displayMethod, var: display_method}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, display_method: $display_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Languages
#
# GET /resources/languages.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-languages-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/languages.json"
    query: [{name: max, var: max}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max: $max, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Language by ID
#
# GET /resources/languages/{id}.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-languages-id-json" [
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
    path: "/resources/languages/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems
#
# GET /resources/media.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
  --sort: string # * Set of fields to sort the records by. (format: )
  --order: string # * The ascending or descending order. (format: )
  --media-types: string # Find all media items belonging to the specified media type[s]. (format: )
  --name: string # Find all media items containing the provided name, case insensitive. (format: )
  --collection-id: int # Restrict filtering to media items in a specific collection. (format: int32)
  --name-contains: string # Find all media items containing the partial name, case insensitive. (format: )
  --description-contains: string # Find all media items containing the provided partial description, case insensitive. (format: )
  --source-url: string # Find all media items which have the provided sourceUrl, case insensitive. (format: )
  --source-url-contains: string # Find all media items which contain the provided partial sourceUrl, case insensitive. (format: )
  --custom-thumbnail-url: string # Find all media items which have the provided customThumbnailUrl, case insensitive. (format: )
  --custom-thumbnail-url-contains: string # Find all media items which contain the provided partial customThumbnailUrl, case insensitive. (format: )
  --date-content-authored: string # Find all media items authored on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-updated: string # Find all media items updated on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-published: string # Find all media items published on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-reviewed: string # Find all media items reviewed on the provided day (RFC 3339, time ignored). (format: date)
  --date-syndication-captured: string # Find all media items syndicated on the provided day (RFC 3339, time ignored). (format: date)
  --date-syndication-updated: string # Find all media items updated through the syndication system on the provided day, (RFC 3339, time ignored). (format: date)
  --content-authored-since-date: string # Find all media items authored since the provided day (RFC 3339, time ignored). (format: date)
  --content-authored-before-date: string # Find all media items authored before the provided day (RFC 3339, time ignored). (format: date)
  --content-authored-in-range: string # Find all media items authored between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-updated-since-date: string # Find all media items updated since the provided day (RFC 3339, time ignored). (format: date)
  --content-updated-before-date: string # Find all media items updated before the provided day (RFC 3339, time ignored). (format: date)
  --content-updated-in-range: string # Find all media items updated between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-published-since-date: string # Find all media items updated since the provided day (RFC 3339, time ignored). (format: date)
  --content-published-before-date: string # Find all media items published before the provided day (RFC 3339, time ignored). (format: date)
  --content-published-in-range: string # Find all media items published between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-reviewed-since-date: string # Find all media items reviewed since the provided day (RFC 3339, time ignored). (format: date)
  --content-reviewed-before-date: string # Find all media items reviewed before the provided day (RFC 3339, time ignored). (format: date)
  --content-reviewed-in-range: string # Find all media items reviewed between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --syndication-captured-since-date: string # Find all media items authored since the provided day (RFC 3339, time ignored). (format: date)
  --syndication-captured-before-date: string # Find all media items authored before the provided day (RFC 3339, time ignored). (format: date)
  --syndication-captured-in-range: string # Find all media items authored between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --syndication-updated-since-date: string # Find all media items updated since the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-updated-before-date: string # Find all media items updated before the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-updated-in-range: string # Find all media items updated between the provided start and end days, (RFC 3339, comma separated, time ignored). (format: )
  --syndication-visible-since-date: string # Find all media items visible since the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-visible-before-date: string # Find all media items visible before the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-visible-in-range: string # Find all media items visible between the provided start and end days, (RFC 3339, comma separated, time ignored). (format: date)
  --language-id: int # Find all media items written in the language specified by Id. (format: int64)
  --language-name: string # Find all media items written in the language specified by name, case insensitive. (format: )
  --language-iso-code: string # Find all media items written in the language specified by 639-2 isoCode , case insensitive. (format: )
  --hash: string # Find all media items which match the provided hash, case insensitive. (format: )
  --hash-contains: string # Find all media items which match the provided partial hash, case insensitive. (format: )
  --source-id: int # Find all media items that belong to the source specified by Id. (format: int64)
  --source-name: string # Find all media items that belong to the source specified by name, case insensitive. (format: )
  --source-name-contains: string # Find all media items that belong to the source specified by partial name, case insensitive. (format: )
  --source-acronym: string # Find all media items that belong to the source specified by acronym, case insensitive. (format: )
  --source-acronym-contains: string # Find all media items that belong to the source specified by partial acronym, case insensitive. (format: )
  --tag-ids: string # Find only media items tagged with the specified tag Ids. (format: )
  --restrict-to-set: string # Find only media from within the supplied list of Ids. (format: )
  --created-by: string # Find all media items containing the createdBy value. (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media.json"
    query: [{name: max, var: max}, {name: offset, var: offset}, {name: sort, var: sort}, {name: order, var: order}, {name: mediaTypes, var: media_types}, {name: name, var: name}, {name: collectionId, var: collection_id}, {name: nameContains, var: name_contains}, {name: descriptionContains, var: description_contains}, {name: sourceUrl, var: source_url}, {name: sourceUrlContains, var: source_url_contains}, {name: customThumbnailUrl, var: custom_thumbnail_url}, {name: customThumbnailUrlContains, var: custom_thumbnail_url_contains}, {name: dateContentAuthored, var: date_content_authored}, {name: dateContentUpdated, var: date_content_updated}, {name: dateContentPublished, var: date_content_published}, {name: dateContentReviewed, var: date_content_reviewed}, {name: dateSyndicationCaptured, var: date_syndication_captured}, {name: dateSyndicationUpdated, var: date_syndication_updated}, {name: contentAuthoredSinceDate, var: content_authored_since_date}, {name: contentAuthoredBeforeDate, var: content_authored_before_date}, {name: contentAuthoredInRange, var: content_authored_in_range}, {name: contentUpdatedSinceDate, var: content_updated_since_date}, {name: contentUpdatedBeforeDate, var: content_updated_before_date}, {name: contentUpdatedInRange, var: content_updated_in_range}, {name: contentPublishedSinceDate, var: content_published_since_date}, {name: contentPublishedBeforeDate, var: content_published_before_date}, {name: contentPublishedInRange, var: content_published_in_range}, {name: contentReviewedSinceDate, var: content_reviewed_since_date}, {name: contentReviewedBeforeDate, var: content_reviewed_before_date}, {name: contentReviewedInRange, var: content_reviewed_in_range}, {name: syndicationCapturedSinceDate, var: syndication_captured_since_date}, {name: syndicationCapturedBeforeDate, var: syndication_captured_before_date}, {name: syndicationCapturedInRange, var: syndication_captured_in_range}, {name: syndicationUpdatedSinceDate, var: syndication_updated_since_date}, {name: syndicationUpdatedBeforeDate, var: syndication_updated_before_date}, {name: syndicationUpdatedInRange, var: syndication_updated_in_range}, {name: syndicationVisibleSinceDate, var: syndication_visible_since_date}, {name: syndicationVisibleBeforeDate, var: syndication_visible_before_date}, {name: syndicationVisibleInRange, var: syndication_visible_in_range}, {name: languageId, var: language_id}, {name: languageName, var: language_name}, {name: languageIsoCode, var: language_iso_code}, {name: hash, var: hash}, {name: hashContains, var: hash_contains}, {name: sourceId, var: source_id}, {name: sourceName, var: source_name}, {name: sourceNameContains, var: source_name_contains}, {name: sourceAcronym, var: source_acronym}, {name: sourceAcronymContains, var: source_acronym_contains}, {name: tagIds, var: tag_ids}, {name: restrictToSet, var: restrict_to_set}, {name: createdBy, var: created_by}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max: $max, offset: $offset, sort: $sort, order: $order, media_types: $media_types, name: $name, collection_id: $collection_id, name_contains: $name_contains, description_contains: $description_contains, source_url: $source_url, source_url_contains: $source_url_contains, custom_thumbnail_url: $custom_thumbnail_url, custom_thumbnail_url_contains: $custom_thumbnail_url_contains, date_content_authored: $date_content_authored, date_content_updated: $date_content_updated, date_content_published: $date_content_published, date_content_reviewed: $date_content_reviewed, date_syndication_captured: $date_syndication_captured, date_syndication_updated: $date_syndication_updated, content_authored_since_date: $content_authored_since_date, content_authored_before_date: $content_authored_before_date, content_authored_in_range: $content_authored_in_range, content_updated_since_date: $content_updated_since_date, content_updated_before_date: $content_updated_before_date, content_updated_in_range: $content_updated_in_range, content_published_since_date: $content_published_since_date, content_published_before_date: $content_published_before_date, content_published_in_range: $content_published_in_range, content_reviewed_since_date: $content_reviewed_since_date, content_reviewed_before_date: $content_reviewed_before_date, content_reviewed_in_range: $content_reviewed_in_range, syndication_captured_since_date: $syndication_captured_since_date, syndication_captured_before_date: $syndication_captured_before_date, syndication_captured_in_range: $syndication_captured_in_range, syndication_updated_since_date: $syndication_updated_since_date, syndication_updated_before_date: $syndication_updated_before_date, syndication_updated_in_range: $syndication_updated_in_range, syndication_visible_since_date: $syndication_visible_since_date, syndication_visible_before_date: $syndication_visible_before_date, syndication_visible_in_range: $syndication_visible_in_range, language_id: $language_id, language_name: $language_name, language_iso_code: $language_iso_code, hash: $hash, hash_contains: $hash_contains, source_id: $source_id, source_name: $source_name, source_name_contains: $source_name_contains, source_acronym: $source_acronym, source_acronym_contains: $source_acronym_contains, tag_ids: $tag_ids, restrict_to_set: $restrict_to_set, created_by: $created_by
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the list of featured content in the syndication system
#
# GET /resources/media/featured.json
# Returns: table<campaigns: list<record>, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list<record>, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record<id: int, isActive: bool, isoCode: string, name: string>, mediaType: string, name: string, source: record<acronym: string, contactEmail: string, id: int, largeLogoUrl: string, name: string, smallLogoUrl: string, websiteUrl: string>, sourceUrl: string, targetUrl: string>
export def "get-resources-media-featured-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media/featured.json"
    query: [{name: sort, var: sort}, {name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    sort: $sort, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems by popularity
#
# GET /resources/media/mostPopularMedia.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-most-popular-media-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media/mostPopularMedia.{format}"
    path_params: [{name: format, var: format}]
    query: [{name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems by search query
#
# GET /resources/media/searchResults.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-search-results-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query supplied by the user (required, format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media/searchResults.json"
    query: [{name: q, var: q, required: true}, {name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    q: $q, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItem by ID
#
# GET /resources/media/{id}.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-id-json" [
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
    path: "/resources/media/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get content for MediaItem
#
# GET /resources/media/{id}/content
# Returns: string
export def "get-resources-media-id-content" [
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
  --called-by-build: oneof<nothing, bool> # The method that called this method (format: )
]: nothing -> any {
  http-request {
    method: get
    path: "/resources/media/{id}/content"
    path_params: [{name: id, var: id}]
    query: [{name: calledByBuild, var: called_by_build}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, called_by_build: $called_by_build
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get embed code for MediaItem
#
# GET /resources/media/{id}/embed.json
# Returns: string
export def "get-resources-media-id-embed-json" [
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
  --flavor: string # Currently supports 'iframe', defaults to 'javascript'. (format: )
  --width: int # The width of the generated iframe. (format: int32)
  --height: int # The height of the generated iframe. (format: int32)
  --iframe-name: string # The name of the iframe element (format: )
  --exclude-jquery: oneof<nothing, bool> # Should a reference to the JQuery Library be omitted? (format: , default: false)
  --exclude-div: oneof<nothing, bool> # Should the div to insert content into be omitted? (format: , default: false)
  --div-id: string # Should the div to insert content into have a specific name? (format: )
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> any {
  http-request {
    method: get
    path: "/resources/media/{id}/embed.json"
    path_params: [{name: id, var: id}]
    query: [{name: flavor, var: flavor}, {name: width, var: width}, {name: height, var: height}, {name: iframeName, var: iframe_name}, {name: excludeJquery, var: exclude_jquery}, {name: excludeDiv, var: exclude_div}, {name: divId, var: div_id}, {name: displayMethod, var: display_method}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, flavor: $flavor, width: $width, height: $height, iframe_name: $iframe_name, exclude_jquery: $exclude_jquery, exclude_div: $exclude_div, div_id: $div_id, display_method: $display_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tag by ID
#
# GET /resources/media/{id}/preview.jpg
# Returns: record
export def "get-resources-media-id-preview-jpg" [
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
    path: "/resources/media/{id}/preview.jpg"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get related MediaItems by ID
#
# GET /resources/media/{id}/relatedMedia.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-id-related-media-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media/{id}/relatedMedia.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: max, var: max}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, max: $max, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get syndicated content for MediaItem
#
# GET /resources/media/{id}/syndicate.{format}
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>>
export def "get-resources-media-id-syndicate-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css-class: string # The css class to target for extraction. (format: , default: syndicate)
  --strip-styles: oneof<nothing, bool> # Remove in-line styles from content. (format: , default: false)
  --strip-scripts: oneof<nothing, bool> # Remove script tags from content. (format: , default: false)
  --strip-images: oneof<nothing, bool> # Remove image tags from content. (format: , default: false)
  --strip-breaks: oneof<nothing, bool> # Remove break tags from content. (format: , default: false)
  --strip-classes: oneof<nothing, bool> # Remove class attributes from content (except 'syndicate'). (format: , default: false)
  --font-size: int # Set font size (in points) of p, div, and span tags. (format: int32)
  --image-float: string # Accepts valid CSS float options, such as 'left' or 'right'. Will inject a style into the content before rendering. (format: )
  --image-margin: string # Accepts 4 CSV values representing pixel sizes of margin similar to CSS. Default format is 'north,east,south,west' - for example '0,10,10,0' would put a 10 pixel margin on the right and bottom sides of an image. Will inject a style into the content before rendering. (format: )
  --autoplay: oneof<nothing, bool> # If content is a video, the embeded video will auto play when loaded. (format: , default: true)
  --rel: oneof<nothing, bool> # If content is a video, related items will be shown at the end of playback. (format: , default: false)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/resources/media/{id}/syndicate.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: cssClass, var: css_class}, {name: stripStyles, var: strip_styles}, {name: stripScripts, var: strip_scripts}, {name: stripImages, var: strip_images}, {name: stripBreaks, var: strip_breaks}, {name: stripClasses, var: strip_classes}, {name: font-size, var: font_size}, {name: imageFloat, var: image_float}, {name: imageMargin, var: image_margin}, {name: autoplay, var: autoplay}, {name: rel, var: rel}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, css_class: $css_class, strip_styles: $strip_styles, strip_scripts: $strip_scripts, strip_images: $strip_images, strip_breaks: $strip_breaks, strip_classes: $strip_classes, font_size: $font_size, image_float: $image_float, image_margin: $image_margin, autoplay: $autoplay, rel: $rel
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get JPG thumbnail for MediaItem
#
# GET /resources/media/{id}/thumbnail.jpg
# Returns: record
export def "get-resources-media-id-thumbnail-jpg" [
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
    path: "/resources/media/{id}/thumbnail.jpg"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Youtube metadata for MediaItem
#
# GET /resources/media/{id}/youtubeMetaData.json
# Returns: record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: list<record>>
export def "get-resources-media-id-youtube-meta-data-json" [
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
    path: "/resources/media/{id}/youtubeMetaData.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaTypes
#
# GET /resources/mediaTypes.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-media-types-format" [
  format: string
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
    path: "/resources/mediaTypes.{format}"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Sources
#
# GET /resources/sources.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-sources-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/sources.json"
    query: [{name: max, var: max}, {name: offset, var: offset}, {name: sort, var: sort}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    max: $max, offset: $offset, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Source by ID
#
# GET /resources/sources/{id}.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-sources-id-json" [
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
    path: "/resources/sources/{id}.json"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems for Source
#
# GET /resources/sources/{id}/syndicate.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-sources-id-syndicate-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/sources/{id}/syndicate.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: displayMethod, var: display_method}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, display_method: $display_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tags
#
# GET /resources/tags.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --name: string # Return tags[s] matching the supplied name (format: )
  --name-contains: string # Return tags which contain the supplied partial name. (format: )
  --media-id: int # Return tags associated with the supplied media id. (format: int64)
  --type-id: int # Return tags belonging to the supplied tag type id. (format: int64)
  --type-name: string # Return tags belonging to the supplied tag type name. (format: )
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/tags.{format}"
    path_params: [{name: format, var: format}]
    query: [{name: sort, var: sort}, {name: max, var: max}, {name: offset, var: offset}, {name: name, var: name}, {name: nameContains, var: name_contains}, {name: mediaId, var: media_id}, {name: typeId, var: type_id}, {name: typeName, var: type_name}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format, sort: $sort, max: $max, offset: $offset, name: $name, name_contains: $name_contains, media_id: $media_id, type_id: $type_id, type_name: $type_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get TagLanguages
#
# GET /resources/tags/tagLanguages.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-tag-languages-format" [
  format: string
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
    path: "/resources/tags/tagLanguages.{format}"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems for Tag
#
# GET /resources/tags/tagTypes.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-tag-types-format" [
  format: string
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
    path: "/resources/tags/tagTypes.{format}"
    path_params: [{name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get Tag by ID
#
# GET /resources/tags/{id}.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-id-format" [
  id: int
  format: string
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
    path: "/resources/tags/{id}.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems for Tag
#
# GET /resources/tags/{id}/media.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-id-media-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/tags/{id}/media.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: sort, var: sort}, {name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, sort: $sort, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get related Tags by ID
#
# GET /resources/tags/{id}/related.{format}
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-tags-id-related-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/tags/{id}/related.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: sort, var: sort}, {name: max, var: max}, {name: offset, var: offset}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, sort: $sort, max: $max, offset: $offset
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get MediaItems for Tag
#
# GET /resources/tags/{id}/syndicate.{format}
# Returns: string
export def "get-resources-tags-id-syndicate-format" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> any {
  http-request {
    method: get
    path: "/resources/tags/{id}/syndicate.{format}"
    path_params: [{name: id, var: id}, {name: format, var: format}]
    query: [{name: displayMethod, var: display_method}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, format: $format, display_method: $display_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get UserMediaList by ID
#
# GET /resources/userMediaLists/{id}.json
# Returns: table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>>
export def "get-resources-user-media-lists-id-json" [
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
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: int64)
]: nothing -> oneof<list<any>, record, string, nothing> {
  http-request {
    method: get
    path: "/resources/userMediaLists/{id}.json"
    path_params: [{name: id, var: id}]
    query: [{name: displayMethod, var: display_method}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, display_method: $display_method
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
