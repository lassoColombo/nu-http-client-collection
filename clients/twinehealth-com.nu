# Auto-generated client for Fitbit Plus API v7.78.1
# Source: https://api.apis.guru/v2/specs/twinehealth.com/v7.78.1/openapi.json
# Auth: --token flag or $env.FITBIT_PLUS_API_TOKEN

const CLIENT = {
  base_url: "https://api.twinehealth.com/pub"
  token_env_var: "FITBIT_PLUS_API_TOKEN"
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

def base-url-completer [] { ["https://api.twinehealth.com/pub"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def filter-type-completer [] { ["office-visit" "plan-check-in" "reminder" "telephone-call" "video-call"] }
def include-completer [] { ["owner"] }
def sort-completer [] { ["-send_time" "send_time"] }
def include-completer-1 [] { ["patient" "questions"] }
def include-completer-2 [] { ["patient"] }
def include-completer-3 [] { ["answer" "question_definition"] }
def include-completer-4 [] { ["groups" "organization"] }
def include-completer-5 [] { ["actions" "bundles" "current_results" "patient"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    create-action: "record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-action: "record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<count: int, req_id: string>>"
    update-action: "record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    create-bundle: "record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-bundle: "record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<count: int, req_id: string>>"
    update-bundle: "record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-calendar-events: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    create-calendar-event: "record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-calendar-event: "record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    update-calendar-event: "record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    create-calendar-event-response: "record<data: record<attributes: record<attendee: record, response_status: string>, relationships: record<calendar_event: record, user: record>, type: string>>"
    fetch-coaches: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-coach: "record<data: record<attributes: record<first_name: string, last_name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-email-histories: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-email-history: "record<data: record<attributes: record<email_address: string, email_type: string, send_time: string, status_times: record, twine_email_id: string>, id: string, relationships: record<receiver: record, sender: record>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-groups: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    create-group: "record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-group: "record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profiles: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profile: "record<data: record<attributes: record<stats: list>, id: string, links: record<self: string>, relationships: record<patient: record, questions: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profile-answers: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profile-answer: "record<data: record<attributes: record<history: list, latest: record, question_id: string>, id: string, links: record<self: string>, relationships: record<patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profile-questions: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-health-profile-question: "record<data: record<attributes: record, id: string, links: record<self: string>, relationships: record<answer: record, profile: record, question_definition: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    fetch-health-question-definitions: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-health-question-definition: "record<data: record<attributes: record<category: string, format: record, requirements: list, text: string>, id: string, links: record<self: string>, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-token: "record<data: record<attributes: record<access_token: string, expires_in: int, refresh_token: string, token_type: string>, id: string, relationships: record<groups: record, organization: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-token-groups: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-token-organization: "record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-organization: "record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-patients: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    create-patient: "record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    upsert-patient: "record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-patient: "record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<count: int, req_id: string>>"
    update-patient: "record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-patient-coaches: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-patient-groups: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-patient-health-metrics: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    create-patient-health-metric: "record<data: record<attributes: record<code: record, diastolic: float, occurred_at: string, systolic: float, type: string, unit: string, value: any>, id: string, relationships: record<patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-patient-health-metric: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-patient-plan-summaries: "record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    fetch-patient-plan-summary: "record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>"
    update-patient-plan-summary: "record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-patient-health-results: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-patient-health-result: "record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>"
    fetch-rewards: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-reward: "record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-reward: "record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-reward-earnings: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-reward-earning: "record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-reward-earning: "record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-reward-earning-fulfillments: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-reward-earning-fulfillment: "record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-reward-earning-fulfillment: "record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-reward-programs: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-reward-program: "record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-reward-program: "record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<count: int, req_id: string>>"
    fetch-reward-program-group: "record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>"
    fetch-reward-program-activations: "record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>"
    create-reward-program-activation: "record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>"
    fetch-reward-program-activation: "record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<count: int, req_id: string>>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-action" "fetch-action" "update-action" "create-bundle" "fetch-bundle" "update-bundle" "fetch-calendar-events" "create-calendar-event" "delete-calendar-event" "fetch-calendar-event" "update-calendar-event" "create-calendar-event-response" "fetch-coaches" "fetch-coach" "fetch-email-histories" "fetch-email-history" "fetch-groups" "create-group" "fetch-group" "fetch-health-profiles" "fetch-health-profile" "fetch-health-profile-answers" "fetch-health-profile-answer" "fetch-health-profile-questions" "fetch-health-profile-question" "fetch-health-question-definitions" "fetch-health-question-definition" "create-token" "fetch-token-groups" "fetch-token-organization" "fetch-organization" "fetch-patients" "create-patient" "upsert-patient" "fetch-patient" "update-patient" "fetch-patient-coaches" "fetch-patient-groups" "fetch-patient-health-metrics" "create-patient-health-metric" "fetch-patient-health-metric" "fetch-patient-plan-summaries" "fetch-patient-plan-summary" "update-patient-plan-summary" "fetch-patient-health-results" "fetch-patient-health-result" "fetch-rewards" "create-reward" "fetch-reward" "fetch-reward-earnings" "create-reward-earning" "fetch-reward-earning" "fetch-reward-earning-fulfillments" "create-reward-earning-fulfillment" "fetch-reward-earning-fulfillment" "fetch-reward-programs" "create-reward-program" "fetch-reward-program" "fetch-reward-program-group" "fetch-reward-program-activations" "create-reward-program-activation" "fetch-reward-program-activation" "commands"] | sort) } | get name | first)
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

# Create action
#
# POST /action
# Returns: record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createAction
export def "create-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/action"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an action
#
# GET /action/{id}
# Returns: record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchAction
export def "fetch-action" [
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
    path: "/action/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update an action
#
# PATCH /action/{id}
# Returns: record<data: record<attributes: record<_thread: string, adherence: record, details: record, effective_from: string, effective_to: string, frequency_goal: record, identifiers: list, intake: record, metric_required: bool, metrics: list, static_title: string, title: string, tracking: bool, type: string, windows: list>, id: string, relationships: record<plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: updateAction
export def "update-action" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/action/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create bundle
#
# POST /bundle
# Returns: record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createBundle
export def "create-bundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/bundle"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a bundle
#
# GET /bundle/{id}
# Returns: record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchBundle
export def "fetch-bundle" [
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
    path: "/bundle/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a bundle
#
# PATCH /bundle/{id}
# Returns: record<data: record<attributes: record<_thread: string, effective_from: string, effective_to: string, title: string, type: string>, id: string, relationships: record<actions: record, plan: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: updateBundle
export def "update-bundle" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/bundle/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List calendar events
#
# GET /calendar_event
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchCalendarEvents
export def "fetch-calendar-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch calendar event. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-attendees: string # Comma-separated list of coach or patient ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, `filter[organization]`, or `filter[attendees]`.
  --filter-type: string@filter-type-completer # Calendar event type
  --filter-completed: oneof<nothing, bool> # If not specified, return all calendar events. If set to `true` return only events marked as completed, if set to `false`, return only events not marked as completed yet.
  --filter-start-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events starting in November 2017 (America/New_York): `filter[start_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-end-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events ending in November 2017 (America/New_York): `filter[end_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-completed-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events completed in November 2017 (America/New_York): `filter[completed_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for events updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/calendar_event"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: "filter[attendees]", var: filter_attendees}, {name: "filter[type]", var: filter_type}, {name: "filter[completed]", var: filter_completed}, {name: "filter[start_at]", var: filter_start_at}, {name: "filter[end_at]", var: filter_end_at}, {name: "filter[completed_at]", var: filter_completed_at}, {name: "filter[created_at]", var: filter_created_at}, {name: "filter[updated_at]", var: filter_updated_at}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[cursor]", var: page_cursor}, {name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, filter_attendees: $filter_attendees, filter_type: $filter_type, filter_completed: $filter_completed, filter_start_at: $filter_start_at, filter_end_at: $filter_end_at, filter_completed_at: $filter_completed_at, filter_created_at: $filter_created_at, filter_updated_at: $filter_updated_at, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_cursor: $page_cursor, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create calendar event
#
# POST /calendar_event
# Returns: record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createCalendarEvent
export def "create-calendar-event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "calendar_event"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendar_event"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Delete a calendar event
#
# DELETE /calendar_event/{id}
# operationId: deleteCalendarEvent
export def "delete-calendar-event" [
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
    path: "/calendar_event/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a calendar event
#
# GET /calendar_event/{id}
# Returns: record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchCalendarEvent
export def "fetch-calendar-event" [
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
    path: "/calendar_event/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a calendar event
#
# PATCH /calendar_event/{id}
# Returns: record<data: record<attributes: record<all_day: bool, attendees: list, completed_at: string, completed_by: record, description: string, end_at: string, location: string, start_at: string, time_zone: string, title: string, type: string>, id: string, links: record<self: string>, relationships: record<owner: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: updateCalendarEvent
export def "update-calendar-event" [
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
  --data: record # shape: {attributes?: record, id: string, relationships?: record, type: "calendar_event"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/calendar_event/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create calendar event response
#
# POST /calendar_event_response
# Returns: record<data: record<attributes: record<attendee: record, response_status: string>, relationships: record<calendar_event: record, user: record>, type: string>>
# operationId: createCalendarEventResponse
export def "create-calendar-event-response" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "calendar_event_response"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/calendar_event_response"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List coaches
#
# GET /coach
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchCoaches
export def "fetch-coaches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/coach"
    query: [{name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_groups: $filter_groups, filter_organization: $filter_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a coach
#
# GET /coach/{id}
# Returns: record<data: record<attributes: record<first_name: string, last_name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchCoach
export def "fetch-coach" [
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
    path: "/coach/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List email histories
#
# GET /email_history
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchEmailHistories
export def "fetch-email-histories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-receiver: string # Fitbit Plus user id of email recipient. Required if filter[sender] is not defined.
  --filter-sender: string # Fitbit Plus user id of email sender. Required if filter[receiver] is not defined.
  --filter-email-type: string # Type of email
  --sort: string@sort-completer # valid sorts: * send_time - ascending by send_time * -send_time - descending by send_time
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/email_history"
    query: [{name: "filter[receiver]", var: filter_receiver}, {name: "filter[sender]", var: filter_sender}, {name: "filter[emailType]", var: filter_email_type}, {name: sort, var: sort}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_receiver: $filter_receiver, filter_sender: $filter_sender, filter_email_type: $filter_email_type, sort: $sort
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an email history
#
# GET /email_history/{id}
# Returns: record<data: record<attributes: record<email_address: string, email_type: string, send_time: string, status_times: record, twine_email_id: string>, id: string, relationships: record<receiver: record, sender: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchEmailHistory
export def "fetch-email-history" [
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
    path: "/email_history/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups
#
# GET /group
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchGroups
export def "fetch-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-organization: string # Organization identifier (required)
  --filter-name: string # Group name
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/group"
    query: [{name: "filter[organization]", var: filter_organization, required: true}, {name: "filter[name]", var: filter_name}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_organization: $filter_organization, filter_name: $filter_name
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a group
#
# POST /group
# Returns: record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createGroup
export def "create-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, id: string, type: "group"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/group"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a group
#
# GET /group/{id}
# Returns: record<data: record<attributes: record<bio: string, name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchGroup
export def "fetch-group" [
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
    path: "/group/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List health profiles
#
# GET /health_profile
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfiles
export def "fetch-health-profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch health profile. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer-1 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[cursor]", var: page_cursor}, {name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_cursor: $page_cursor, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a health profile
#
# GET /health_profile/{id}
# Returns: record<data: record<attributes: record<stats: list>, id: string, links: record<self: string>, relationships: record<patient: record, questions: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfile
export def "fetch-health-profile" [
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
  --include: string@include-completer-1 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List health profile answers
#
# GET /health_profile_answer
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfileAnswers
export def "fetch-health-profile-answers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch healt profile answers. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 50)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
  --include: string@include-completer-2 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile_answer"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[cursor]", var: page_cursor}, {name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_cursor: $page_cursor, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a health profile answer
#
# GET /health_profile_answer/{id}
# Returns: record<data: record<attributes: record<history: list, latest: record, question_id: string>, id: string, links: record<self: string>, relationships: record<patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfileAnswer
export def "fetch-health-profile-answer" [
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
  --include: string@include-completer-2 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile_answer/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List health profile questions
#
# GET /health_profile_question
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfileQuestions
export def "fetch-health-profile-questions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch healt profile questions. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[group]`, or `filter[organization]`.
  --include: string@include-completer-3 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile_question"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a health profile question
#
# GET /health_profile_question/{id}
# Returns: record<data: record<attributes: record, id: string, links: record<self: string>, relationships: record<answer: record, profile: record, question_definition: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthProfileQuestion
export def "fetch-health-profile-question" [
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
  --include: string@include-completer-3 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/health_profile_question/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List health question definitions
#
# GET /health_question_definition
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthQuestionDefinitions
export def "fetch-health-question-definitions" [
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
    path: "/health_question_definition"
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a health question definition
#
# GET /health_question_definition/{id}
# Returns: record<data: record<attributes: record<category: string, format: record, requirements: list, text: string>, id: string, links: record<self: string>, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchHealthQuestionDefinition
export def "fetch-health-question-definition" [
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
    path: "/health_question_definition/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create an oauth token
#
# POST /oauth/token
# Returns: record<data: record<attributes: record<access_token: string, expires_in: int, refresh_token: string, token_type: string>, id: string, relationships: record<groups: record, organization: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createToken
export def "create-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string@include-completer-4 # List of related resources to include in the response
  data: record # shape: {attributes: record, type?: "token"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/oauth/token"
    query: [{name: include, var: include}]
    body: {content_type: "application/json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    include: $include, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the groups for a token
#
# GET /oauth/token/{id}/groups
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchTokenGroups
export def "fetch-token-groups" [
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
    path: "/oauth/token/{id}/groups"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the organization for a token
#
# GET /oauth/token/{id}/organization
# Returns: record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchTokenOrganization
export def "fetch-token-organization" [
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
    path: "/oauth/token/{id}/organization"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get an organization
#
# GET /organization/{id}
# Returns: record<data: record<attributes: record<name: string>, id: string, links: record<self: string>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchOrganization
export def "fetch-organization" [
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
    path: "/organization/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List patients
#
# GET /patient
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatients
export def "fetch-patients" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group ids. Note that either `filter[group]` or `filter[organization]` must be specified.
  --filter-organization: string # Fitbit Plus organization id. Note that either `filter[group]` or `filter[organization]` must be specified.
  --filter-identifier-system: string # Identifier system (example: "MyEHR") - requires a "filter[identifier][value]" parameter
  --filter-identifier-value: string # Identifier value (example: "12345") - requires a "filter[identifier][system]" parameter
  --filter-archived: oneof<nothing, bool> # If not specified, return all patients. If set to 'true' return only archived patients, if set to 'false', return only patients who are not archived.
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for patients created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for patients updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/patient"
    query: [{name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: "filter[identifier][system]", var: filter_identifier_system}, {name: "filter[identifier][value]", var: filter_identifier_value}, {name: "filter[archived]", var: filter_archived}, {name: "filter[created_at]", var: filter_created_at}, {name: "filter[updated_at]", var: filter_updated_at}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[cursor]", var: page_cursor}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_groups: $filter_groups, filter_organization: $filter_organization, filter_identifier_system: $filter_identifier_system, filter_identifier_value: $filter_identifier_value, filter_archived: $filter_archived, filter_created_at: $filter_created_at, filter_updated_at: $filter_updated_at, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_cursor: $page_cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a patient
#
# POST /patient
# Returns: record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createPatient
export def "create-patient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Note that `data` can either be a single object or an array of objects matching the schema specified here (bulk create). — shape: {attributes: record, id?: string, relationships?: record, type: "patient"}
  --meta: record # shape: {ignore_duplicates?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patient"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}, {name: meta, var: meta}]}
    accept: ["application/vnd.api+json"]
    ok: [201]
    auth: bearer
  } {
    data: $data, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Upsert patient
#
# PUT /patient
# Returns: record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: upsertPatient
export def "upsert-patient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, id?: string, relationships?: record, type: "patient"}
  meta: record # shape: {query: record}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: put
    path: "/patient"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}, {name: meta, var: meta}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a patient
#
# GET /patient/{id}
# Returns: record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatient
export def "fetch-patient" [
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
    path: "/patient/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a patient
#
# PATCH /patient/{id}
# Returns: record<data: record<attributes: record<addresses: list, archive_history: list, archived: bool, birth_date: string, email_address: string, enrolled_at: string, first_access_at: string, first_name: string, gender: string, identifiers: list, invited_at: string, last_access_at: string, last_name: string, note: string, phone_numbers: list, statement: record, updated_at: string>, id: string, links: record<self: string, twine_web_app: string>, relationships: record<coaches: record, groups: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: updatePatient
export def "update-patient" [
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
  data: record # shape: {attributes: record, id?: string, relationships?: record, type: "patient"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/patient/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List coaches for a patient
#
# GET /patient/{id}/coaches
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientCoaches
export def "fetch-patient-coaches" [
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
    path: "/patient/{id}/coaches"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List groups for a patient
#
# GET /patient/{id}/groups
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientGroups
export def "fetch-patient-groups" [
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
    path: "/patient/{id}/groups"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List patient health metrics
#
# GET /patient_health_metric
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientHealthMetrics
export def "fetch-patient-health-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Filter the patient health metrics for a specified patient. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-cursor: string # Page cursor
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/patient_health_metric"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[cursor]", var: page_cursor}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_cursor: $page_cursor
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create patient health metrics
#
# POST /patient_health_metric
# Returns: record<data: record<attributes: record<code: record, diastolic: float, occurred_at: string, systolic: float, type: string, unit: string, value: any>, id: string, relationships: record<patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createPatientHealthMetric
export def "create-patient-health-metric" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Note that `data` can either be a single object or an array of objects matching the schema specified here (bulk create). — shape: {attributes?: record, id: string, relationships?: record, type: string}
  --meta: record # shape: {ignore_duplicates?: bool}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/patient_health_metric"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}, {name: meta, var: meta}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data, meta: $meta
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a patient health metric
#
# GET /patient_health_metric/{id}
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientHealthMetric
export def "fetch-patient-health-metric" [
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
    path: "/patient_health_metric/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List patient plan summaries
#
# GET /patient_plan_summary
# Returns: record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientPlanSummaries
export def "fetch-patient-plan-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient id to fetch plan summary for. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --include: string@include-completer-5 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/patient_plan_summary"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}, {name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get the plan summary for a patient
#
# GET /patient_plan_summary/{id}
# Returns: record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, included: table<attributes: record, id: string, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientPlanSummary
export def "fetch-patient-plan-summary" [
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
  --include: string@include-completer-5 # List of related resources to include in the response
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/patient_plan_summary/{id}"
    path_params: [{name: id, var: id}]
    query: [{name: include, var: include}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, include: $include
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Update a plan summary
#
# PATCH /patient_plan_summary/{id}
# Returns: record<data: record<attributes: record<adherence: record, critical: record, effective_from: string, time_zone: string, window_notification_times: record, window_order: list>, id: string, links: record<self: string>, relationships: record<actions: record, bundles: record, current_results: record, patient: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: updatePatientPlanSummary
export def "update-patient-plan-summary" [
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
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "patient_plan_summary"}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/patient_plan_summary/{id}"
    path_params: [{name: id, var: id}]
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id, data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List patient health results
#
# GET /result
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientHealthResults
export def "fetch-patient-health-results" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Filter the patient health results for a specified patient (required)
  --filter-actions: string # A comma-separated list of action identifiers
  --filter-start-at: string # Filter results that occurred after the passed ISO date and time string (format: dateTime)
  --filter-end-at: string # Filter results that occurred before the passed ISO date and time string (format: dateTime)
  --filter-threads: string # A comma-separated list of thread identifiers
  --filter-created-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for results created in November 2017 (America/New_York): `filter[created_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --filter-updated-at: string # The start (inclusive) and end (exclusive) dates are ISO date and time strings separated by `..`. Example for results updated in November 2017 (America/New_York): `filter[updated_at]=2017-11-01T00:00:00-04:00..2017-12-01T00:00:00-05:00`
  --page-number: int # Page number (default: 1)
  --page-size: int # Page size (default: 10)
  --page-limit: int # Page limit (default: 50)
  --page-after: string # Page cursor
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/result"
    query: [{name: "filter[patient]", var: filter_patient, required: true}, {name: "filter[actions]", var: filter_actions}, {name: "filter[start_at]", var: filter_start_at}, {name: "filter[end_at]", var: filter_end_at}, {name: "filter[threads]", var: filter_threads}, {name: "filter[created_at]", var: filter_created_at}, {name: "filter[updated_at]", var: filter_updated_at}, {name: "page[number]", var: page_number}, {name: "page[size]", var: page_size}, {name: "page[limit]", var: page_limit}, {name: "page[after]", var: page_after}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_actions: $filter_actions, filter_start_at: $filter_start_at, filter_end_at: $filter_end_at, filter_threads: $filter_threads, filter_created_at: $filter_created_at, filter_updated_at: $filter_updated_at, page_number: $page_number, page_size: $page_size, page_limit: $page_limit, page_after: $page_after
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a patient health result
#
# GET /result/{id}
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<last: string, next: string, prev: string, self: string>, meta: record<count: int, req_id: string>>
# operationId: fetchPatientHealthResult
export def "fetch-patient-health-result" [
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
    path: "/result/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List rewards
#
# GET /reward
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewards
export def "fetch-rewards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-reward-program-activation: string # Reward program activation identifier
  --filter-thread: string # Thread identifier
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reward"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[reward_program_activation]", var: filter_reward_program_activation}, {name: "filter[thread]", var: filter_thread}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_reward_program_activation: $filter_reward_program_activation, filter_thread: $filter_thread, filter_groups: $filter_groups, filter_organization: $filter_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a reward
#
# POST /reward
# Returns: record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createReward
export def "create-reward" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id?: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reward"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reward
#
# GET /reward/{id}
# Returns: record<data: record<attributes: record<_thread: string, allocated_at: string, allocated_unit: string, allocated_value: float, description: string, earned_at: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, target_at: string>, id: string, relationships: record<patient: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchReward
export def "fetch-reward" [
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
    path: "/reward/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reward earnings
#
# GET /reward_earning
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardEarnings
export def "fetch-reward-earnings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Group identifiers (required)
  --filter-patient: string # Patient identifier (required)
  --filter-ready-for-fulfillment: oneof<nothing, bool> # If true, only returns those reward earnings for which ready_for_fulfillment is true and fulfilled_at is null. If false, only returns those reward earnings for which ready_for_fulfillment is false and fulfilled_at is null.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reward_earning"
    query: [{name: "filter[groups]", var: filter_groups, required: true}, {name: "filter[patient]", var: filter_patient, required: true}, {name: "filter[ready_for_fulfillment]", var: filter_ready_for_fulfillment}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_groups: $filter_groups, filter_patient: $filter_patient, filter_ready_for_fulfillment: $filter_ready_for_fulfillment
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a reward earning
#
# POST /reward_earning
# Returns: record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createRewardEarning
export def "create-reward-earning" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id?: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reward_earning"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reward earning
#
# GET /reward_earning/{id}
# Returns: record<data: record<attributes: record<earned_at: string, earned_unit: string, earned_value: float, fulfilled_at: string, fulfilled_value: float, ready_for_fulfillment: bool>, id: string, relationships: record<group: record, patient: record, reward: record, reward_program_activation: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardEarning
export def "fetch-reward-earning" [
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
    path: "/reward_earning/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reward earning fulfillments
#
# GET /reward_earning_fulfillment
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardEarningFulfillments
export def "fetch-reward-earning-fulfillments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier (required)
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reward_earning_fulfillment"
    query: [{name: "filter[patient]", var: filter_patient, required: true}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a reward earning fulfillment
#
# POST /reward_earning_fulfillment
# Returns: record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createRewardEarningFulfillment
export def "create-reward-earning-fulfillment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id?: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reward_earning_fulfillment"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reward earning fulfillment
#
# GET /reward_earning_fulfillment/{id}
# Returns: record<data: record<attributes: record<fulfilled_at: string, fulfilled_unit: string, fulfilled_value: float>, id: string, relationships: record<patient: record, reward_earning: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardEarningFulfillment
export def "fetch-reward-earning-fulfillment" [
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
    path: "/reward_earning_fulfillment/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reward programs
#
# GET /reward_program
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardPrograms
export def "fetch-reward-programs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-groups: string # Comma-separated list of group identifiers. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[groups]`, `filter[organization]`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reward_program"
    query: [{name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_groups: $filter_groups, filter_organization: $filter_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a reward program
#
# POST /reward_program
# Returns: record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createRewardProgram
export def "create-reward-program" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id?: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reward_program"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reward program
#
# GET /reward_program/{id}
# Returns: record<data: record<attributes: record<budget_unit: string, budget_value: float, description: string, duration_active: float, end_at: string, frozen: bool, fulfill_as_earned: bool, name: string, start_at: string, tagline: string>, id: string, relationships: record<group: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardProgram
export def "fetch-reward-program" [
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
    path: "/reward_program/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get group for a reward program
#
# GET /reward_program/{id}/group
# Returns: record<data: table<attributes: record, id: string, links: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardProgramGroup
export def "fetch-reward-program-group" [
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
    path: "/reward_program/{id}/group"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# List reward program activations
#
# GET /reward_program_activation
# Returns: record<data: table<attributes: record, id: string, relationships: record, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardProgramActivations
export def "fetch-reward-program-activations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-patient: string # Patient identifier. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-groups: string # Comma-separated list of group ids. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
  --filter-organization: string # Fitbit Plus organization id. Note that one of the following filters must be specified: `filter[patient]`, `filter[groups]`, `filter[organization]`.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/reward_program_activation"
    query: [{name: "filter[patient]", var: filter_patient}, {name: "filter[groups]", var: filter_groups}, {name: "filter[organization]", var: filter_organization}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    filter_patient: $filter_patient, filter_groups: $filter_groups, filter_organization: $filter_organization
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Create a reward program activation
#
# POST /reward_program_activation
# Returns: record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<ignored: list<string>, req_id: string>>
# operationId: createRewardProgramActivation
export def "create-reward-program-activation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id?: string, relationships?: record, type: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/reward_program_activation"
    body: {content_type: "application/vnd.api+json", kind: json, fields: [{name: data, var: data}]}
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    data: $data
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Get a reward program activation
#
# GET /reward_program_activation/{id}
# Returns: record<data: record<attributes: record<activated_at: string, active: bool, allocated_count: float, budget_unit: string, deactivated_at: string, earned_count: float, expires_at: string, fulfill_as_earned: bool, total_allocated_value: float, total_earned_value: float>, id: string, relationships: record<patient: record, reward_program: record>, type: string>, meta: record<count: int, req_id: string>>
# operationId: fetchRewardProgramActivation
export def "fetch-reward-program-activation" [
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
    path: "/reward_program_activation/{id}"
    path_params: [{name: id, var: id}]
    accept: ["application/vnd.api+json"]
    ok: [200]
    auth: bearer
  } {
    id: $id
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
