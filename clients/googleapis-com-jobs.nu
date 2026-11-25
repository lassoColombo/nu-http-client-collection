# Auto-generated client for Cloud Talent Solution API v3p1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/jobs/v3p1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_TALENT_SOLUTION_API_TOKEN

const CLIENT = {
  base_url: "https://jobs.googleapis.com"
  token_env_var: "CLOUD_TALENT_SOLUTION_API_TOKEN"
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

def base-url-completer [] { ["https://jobs.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def scope-completer [] { ["COMPLETION_SCOPE_UNSPECIFIED" "PUBLIC" "TENANT"] }
def type-completer [] { ["COMBINED" "COMPANY_NAME" "COMPLETION_TYPE_UNSPECIFIED" "JOB_TITLE"] }
def job-view-completer [] { ["JOB_VIEW_FULL" "JOB_VIEW_ID_ONLY" "JOB_VIEW_MINIMAL" "JOB_VIEW_SMALL" "JOB_VIEW_UNSPECIFIED"] }
def diversification-level-completer [] { ["DISABLED" "DIVERSIFICATION_LEVEL_UNSPECIFIED" "SIMPLE"] }
def search-mode-completer [] { ["FEATURED_JOB_SEARCH" "JOB_SEARCH" "SEARCH_MODE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let return_types = {
    jobs-projects-jobs-delete: "record"
    jobs-projects-operations-get: "record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>"
    jobs-projects-jobs-patch: "record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>"
    jobs-projects-complete: "record<completionResults: table<imageUri: string, suggestion: string, type: string>, metadata: record<requestId: string>>"
    jobs-projects-client-events-create: "record<createTime: string, eventId: string, extraInfo: record, jobEvent: record<jobs: list<string>, type: string>, parentEventId: string, requestId: string>"
    jobs-projects-companies-list: "record<companies: table<careerSiteUri: string, derivedInfo: record, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list, name: string, size: string, suspended: bool, websiteUri: string>, metadata: record<requestId: string>, nextPageToken: string>"
    jobs-projects-companies-create: "record<careerSiteUri: string, derivedInfo: record<headquartersLocation: record<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>>, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list<string>, name: string, size: string, suspended: bool, websiteUri: string>"
    jobs-projects-jobs-list: "record<jobs: table<addresses: list, applicationInfo: record, companyDisplayName: string, companyName: string, compensationInfo: record, customAttributes: record, degreeTypes: list, department: string, derivedInfo: record, description: string, employmentTypes: list, incentives: string, jobBenefits: list, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>, metadata: record<requestId: string>, nextPageToken: string>"
    jobs-projects-jobs-create: "record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>"
    jobs-projects-jobs-batch-delete: "record"
    jobs-projects-jobs-search: "record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int>"
    jobs-projects-jobs-search-for-alert: "record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int>"
  }
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["jobs-projects-jobs-delete" "jobs-projects-operations-get" "jobs-projects-jobs-patch" "jobs-projects-complete" "jobs-projects-client-events-create" "jobs-projects-companies-list" "jobs-projects-companies-create" "jobs-projects-jobs-list" "jobs-projects-jobs-create" "jobs-projects-jobs-batch-delete" "jobs-projects-jobs-search" "jobs-projects-jobs-search-for-alert" "commands"] | sort) } | get name | first)
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

# Deletes the specified job. Typically, the job becomes unsearchable within 10 seconds, but it may take up to 5 minutes.
#
# DELETE /v3p1beta1/{name}
# Returns: record
# operationId: jobs.projects.jobs.delete
export def "jobs-projects-jobs-delete" [
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
    path: "/v3p1beta1/{name}"
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

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v3p1beta1/{name}
# Returns: record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record>
# operationId: jobs.projects.operations.get
export def "jobs-projects-operations-get" [
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
    path: "/v3p1beta1/{name}"
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

# Updates specified job. Typically, updated contents become visible in search results within 10 seconds, but it may take up to 5 minutes.
#
# PATCH /v3p1beta1/{name}
# Returns: record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>
# operationId: jobs.projects.jobs.patch
export def "jobs-projects-jobs-patch" [
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
  --job: record # A Job resource represents a job posting (also referred to as a "job listing" or "job requisition"). A job belongs to a Company, which is the hiring entity responsible for the job. — shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
  --update-mask: string # Optional but strongly recommended to be provided for the best service experience. If update_mask is provided, only the specified fields in job are updated. Otherwise all the fields are updated. A field mask to restrict the fields that are updated. Only top level fields of Job are supported. (format: google-fieldmask)
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: patch
    path: "/v3p1beta1/{name}"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: job, var: job}, {name: updateMask, var: update_mask}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job: $job, update_mask: $update_mask
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Completes the specified prefix with keyword suggestions. Intended for use by a job search auto-complete search box.
#
# GET /v3p1beta1/{name}:complete
# Returns: record<completionResults: table<imageUri: string, suggestion: string, type: string>, metadata: record<requestId: string>>
# operationId: jobs.projects.complete
export def "jobs-projects-complete" [
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
  --company-name: string # Optional. If provided, restricts completion to specified company. The format is "projects/{project_id}/companies/{company_id}", for example, "projects/api-test-project/companies/foo".
  --language-code: string # Deprecated. Use language_codes instead. Optional. The language of the query. This is the BCP-47 language code, such as "en-US" or "sr-Latn". For more information, see [Tags for Identifying Languages](https://tools.ietf.org/html/bcp47). For CompletionType.JOB_TITLE type, only open jobs with the same language_code are returned. For CompletionType.COMPANY_NAME type, only companies having open jobs with the same language_code are returned. For CompletionType.COMBINED type, only open jobs with the same language_code or companies having open jobs with the same language_code are returned. The maximum number of allowed characters is 255.
  --language-codes: list<string> # Optional. The list of languages of the query. This is the BCP-47 language code, such as "en-US" or "sr-Latn". For more information, see [Tags for Identifying Languages](https://tools.ietf.org/html/bcp47). For CompletionType.JOB_TITLE type, only open jobs with the same language_codes are returned. For CompletionType.COMPANY_NAME type, only companies having open jobs with the same language_codes are returned. For CompletionType.COMBINED type, only open jobs with the same language_codes or companies having open jobs with the same language_codes are returned. The maximum number of allowed characters is 255.
  --page-size: int # Required. Completion result count. The maximum allowed page size is 10.
  --query: string # Required. The query used to generate suggestions. The maximum number of allowed characters is 255.
  --scope: string@scope-completer # Optional. The scope of the completion. The defaults is CompletionScope.PUBLIC.
  --type: string@type-completer # Optional. The completion topic. The default is CompletionType.COMBINED.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3p1beta1/{name}:complete"
    path_params: [{name: name, var: name}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: companyName, var: company_name}, {name: languageCode, var: language_code}, {name: languageCodes, var: language_codes, style: multi}, {name: pageSize, var: page_size}, {name: query, var: query}, {name: scope, var: scope}, {name: type, var: type}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    name: $name, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, company_name: $company_name, language_code: $language_code, language_codes: $language_codes, page_size: $page_size, query: $query, scope: $scope, type: $type
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Report events issued when end user interacts with customer's application that uses Cloud Talent Solution. You may inspect the created events in [self service tools](https://console.cloud.google.com/talent-solution/overview). [Learn more](https://cloud.google.com/talent-solution/docs/management-tools) about self service tools.
#
# POST /v3p1beta1/{parent}/clientEvents
# Returns: record<createTime: string, eventId: string, extraInfo: record, jobEvent: record<jobs: list<string>, type: string>, parentEventId: string, requestId: string>
# operationId: jobs.projects.clientEvents.create
export def "jobs-projects-client-events-create" [
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
  --client-event: record # An event issued when an end user interacts with the application that implements Cloud Talent Solution. Providing this information improves the quality of search and recommendation for the API clients, enabling the service to perform optimally. The number of events sent must be consistent with other calls, such as job searches, issued to the service by the client. — shape: {createTime?: string, eventId?: string, extraInfo?: record, jobEvent?: record, parentEventId?: string, requestId?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/clientEvents"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: clientEvent, var: client_event}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, client_event: $client_event
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists all companies associated with the service account.
#
# GET /v3p1beta1/{parent}/companies
# Returns: record<companies: table<careerSiteUri: string, derivedInfo: record, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list, name: string, size: string, suspended: bool, websiteUri: string>, metadata: record<requestId: string>, nextPageToken: string>
# operationId: jobs.projects.companies.list
export def "jobs-projects-companies-list" [
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
  --page-size: int # Optional. The maximum number of companies to be returned, at most 100. Default is 100 if a non-positive number is provided.
  --page-token: string # Optional. The starting indicator from which to return results.
  --require-open-jobs: oneof<nothing, bool> # Optional. Set to true if the companies requested must have open jobs. Defaults to false. If true, at most page_size of companies are fetched, among which only those with open jobs are returned.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3p1beta1/{parent}/companies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: requireOpenJobs, var: require_open_jobs}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, page_size: $page_size, page_token: $page_token, require_open_jobs: $require_open_jobs
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new company entity.
#
# POST /v3p1beta1/{parent}/companies
# Returns: record<careerSiteUri: string, derivedInfo: record<headquartersLocation: record<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>>, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list<string>, name: string, size: string, suspended: bool, websiteUri: string>
# operationId: jobs.projects.companies.create
export def "jobs-projects-companies-create" [
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
  --company: record # A Company resource represents a company in the service. A company is the entity that owns job postings, that is, the hiring entity responsible for employing applicants for the job position. — shape: {careerSiteUri?: string, derivedInfo?: record, displayName?: string, eeoText?: string, externalId?: string, headquartersAddress?: string, hiringAgency?: bool, imageUri?: string, keywordSearchableJobCustomAttributes?: list<string>, name?: string, size?: "COMPANY_SIZE_UNSPECIFIED"|"MINI"|"SMALL"|"SMEDIUM"|"MEDIUM"|"BIG"|"BIGGER"|"GIANT", suspended?: bool, websiteUri?: string}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/companies"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: company, var: company}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, company: $company
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Lists jobs by filter.
#
# GET /v3p1beta1/{parent}/jobs
# Returns: record<jobs: table<addresses: list, applicationInfo: record, companyDisplayName: string, companyName: string, compensationInfo: record, customAttributes: record, degreeTypes: list, department: string, derivedInfo: record, description: string, employmentTypes: list, incentives: string, jobBenefits: list, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>, metadata: record<requestId: string>, nextPageToken: string>
# operationId: jobs.projects.jobs.list
export def "jobs-projects-jobs-list" [
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
  --filter: string # Required. The filter string specifies the jobs to be enumerated. Supported operator: =, AND The fields eligible for filtering are: * `companyName` * `requisitionId` * `status` Available values: OPEN, EXPIRED, ALL. Defaults to OPEN if no value is specified. At least one of `companyName` and `requisitionId` must present or an INVALID_ARGUMENT error is thrown. Sample Query: * companyName = "projects/api-test-project/companies/123" * companyName = "projects/api-test-project/companies/123" AND requisitionId = "req-1" * companyName = "projects/api-test-project/companies/123" AND status = "EXPIRED" * requisitionId = "req-1" * requisitionId = "req-1" AND status = "EXPIRED"
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.JOB_VIEW_FULL if no value is specified.
  --page-size: int # Optional. The maximum number of jobs to be returned per page of results. If job_view is set to JobView.JOB_VIEW_ID_ONLY, the maximum allowed page size is 1000. Otherwise, the maximum allowed page size is 100. Default is 100 if empty or a number < 1 is specified.
  --page-token: string # Optional. The starting point of a query result.
]: nothing -> oneof<record, string, nothing> {
  http-request {
    method: get
    path: "/v3p1beta1/{parent}/jobs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}, {name: filter, var: filter}, {name: jobView, var: job_view}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}]
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter, job_view: $job_view, page_size: $page_size, page_token: $page_token
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Creates a new job. Typically, the job becomes searchable within 10 seconds, but it may take up to 5 minutes.
#
# POST /v3p1beta1/{parent}/jobs
# Returns: record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>
# operationId: jobs.projects.jobs.create
export def "jobs-projects-jobs-create" [
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
  --job: record # A Job resource represents a job posting (also referred to as a "job listing" or "job requisition"). A job belongs to a Company, which is the hiring entity responsible for the job. — shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/jobs"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: job, var: job}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, job: $job
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Deletes a list of Jobs by filter.
#
# POST /v3p1beta1/{parent}/jobs:batchDelete
# Returns: record
# operationId: jobs.projects.jobs.batchDelete
export def "jobs-projects-jobs-batch-delete" [
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
  --filter: string # Required. The filter string specifies the jobs to be deleted. Supported operator: =, AND The fields eligible for filtering are: * `companyName` (Required) * `requisitionId` (Required) Sample Query: companyName = "projects/api-test-project/companies/123" AND requisitionId = "req-1"
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/jobs:batchDelete"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: filter, var: filter}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, filter: $filter
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for jobs using the provided SearchJobsRequest. This call constrains the visibility of jobs present in the database, and only returns jobs that the caller has permission to search against.
#
# POST /v3p1beta1/{parent}/jobs:search
# Returns: record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int>
# operationId: jobs.projects.jobs.search
export def "jobs-projects-jobs-search" [
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
  --custom-ranking-info: record # Input only. Custom ranking information for SearchJobsRequest. — shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
  --disable-keyword-match: oneof<nothing, bool> # Optional. Controls whether to disable exact keyword match on Job.job_title, Job.description, Job.company_display_name, Job.locations, Job.qualifications. When disable keyword match is turned off, a keyword match returns jobs that do not match given category filters when there are matching keywords. For example, the query "program manager," a result is returned even if the job posting has the title "software developer," which does not fall into "program manager" ontology, but does have "program manager" appearing in its description. For queries like "cloud" that does not contain title or location specific ontology, jobs with "cloud" keyword matches are returned regardless of this flag's value. Please use Company.keyword_searchable_custom_fields or Company.keyword_searchable_custom_attributes if company specific globally matched custom field/attribute string values is needed. Enabling keyword match improves recall of subsequent search requests. Defaults to false.
  --diversification-level: string@diversification-level-completer # Optional. Controls whether highly similar jobs are returned next to each other in the search results. Jobs are identified as highly similar based on their titles, job categories, and locations. Highly similar results are clustered so that only one representative job of the cluster is displayed to the job seeker higher up in the results, with the other jobs being displayed lower down in the results. Defaults to DiversificationLevel.SIMPLE if no value is specified.
  --enable-broadening: oneof<nothing, bool> # Optional. Controls whether to broaden the search when it produces sparse results. Broadened queries append results to the end of the matching results list. Defaults to false.
  --histogram-facets: record # Input only. Histogram facets to be specified in SearchJobsRequest. — shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
  --histogram-queries: list # Optional. Expression based histogram requests for jobs matching JobQuery. — item shape: {histogramQuery?: string}
  --job-query: record # Input only. The query required to perform a search query. — shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.SMALL if no value is specified.
  --offset: int # Optional. An integer that specifies the current offset (that is, starting result location, amongst the jobs deemed by the API as relevant) in search results. This field is only considered if page_token is unset. The maximum allowed value is 5000. Otherwise an error is thrown. For example, 0 means to return results starting from the first matching job, and 10 means to return from the 11th job. This can be used for pagination, (for example, pageSize = 10 and offset = 10 means to return from the second page). (format: int32)
  --order-by: string # Optional. The criteria determining how search results are sorted. Default is "relevance desc". Supported options are: * `"relevance desc"`: By relevance descending, as determined by the API algorithms. Relevance thresholding of query results is only available with this ordering. * `"posting_publish_time desc"`: By Job.posting_publish_time descending. * `"posting_update_time desc"`: By Job.posting_update_time descending. * `"title"`: By Job.title ascending. * `"title desc"`: By Job.title descending. * `"annualized_base_compensation"`: By job's CompensationInfo.annualized_base_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_base_compensation desc"`: By job's CompensationInfo.annualized_base_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation"`: By job's CompensationInfo.annualized_total_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation desc"`: By job's CompensationInfo.annualized_total_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"custom_ranking desc"`: By the relevance score adjusted to the SearchJobsRequest.custom_ranking_info.ranking_expression with weight factor assigned by SearchJobsRequest.custom_ranking_info.importance_level in descending order. * Location sorting: Use the special syntax to order jobs by distance: "`distance_from('Hawaii')`": Order by distance from Hawaii. "`distance_from(19.89, 155.5)`": Order by distance from a coordinate. "`distance_from('Hawaii'), distance_from('Puerto Rico')`": Order by multiple locations. See details below. "`distance_from('Hawaii'), distance_from(19.89, 155.5)`": Order by multiple locations. See details below. The string can have a maximum of 256 characters. When multiple distance centers are provided, a job that is close to any of the distance centers would have a high rank. When a job has multiple locations, the job location closest to one of the distance centers will be used. Jobs that don't have locations will be ranked at the bottom. Distance is calculated with a precision of 11.3 meters (37.4 feet). Diversification strategy is still applied unless explicitly disabled in diversification_level.
  --page-size: int # Optional. A limit on the number of jobs returned in the search results. Increasing this value above the default value of 10 can increase search response time. The value can be between 1 and 100. (format: int32)
  --page-token: string # Optional. The token specifying the current offset within search results. See SearchJobsResponse.next_page_token for an explanation of how to obtain the next set of query results.
  --request-metadata: record # Input only. Meta information related to the job searcher or entity conducting the job search. This information is used to improve the performance of the service. — shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
  --require-precise-result-size: oneof<nothing, bool> # This field is deprecated.
  --search-mode: string@search-mode-completer # Optional. Mode of a search. Defaults to SearchMode.JOB_SEARCH.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/jobs:search"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: customRankingInfo, var: custom_ranking_info}, {name: disableKeywordMatch, var: disable_keyword_match}, {name: diversificationLevel, var: diversification_level}, {name: enableBroadening, var: enable_broadening}, {name: histogramFacets, var: histogram_facets}, {name: histogramQueries, var: histogram_queries}, {name: jobQuery, var: job_query}, {name: jobView, var: job_view}, {name: offset, var: offset}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: requestMetadata, var: request_metadata}, {name: requirePreciseResultSize, var: require_precise_result_size}, {name: searchMode, var: search_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_ranking_info: $custom_ranking_info, disable_keyword_match: $disable_keyword_match, diversification_level: $diversification_level, enable_broadening: $enable_broadening, histogram_facets: $histogram_facets, histogram_queries: $histogram_queries, job_query: $job_query, job_view: $job_view, offset: $offset, order_by: $order_by, page_size: $page_size, page_token: $page_token, request_metadata: $request_metadata, require_precise_result_size: $require_precise_result_size, search_mode: $search_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}

# Searches for jobs using the provided SearchJobsRequest. This API call is intended for the use case of targeting passive job seekers (for example, job seekers who have signed up to receive email alerts about potential job opportunities), and has different algorithmic adjustments that are targeted to passive job seekers. This call constrains the visibility of jobs present in the database, and only returns jobs the caller has permission to search against.
#
# POST /v3p1beta1/{parent}/jobs:searchForAlert
# Returns: record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int>
# operationId: jobs.projects.jobs.searchForAlert
export def "jobs-projects-jobs-search-for-alert" [
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
  --custom-ranking-info: record # Input only. Custom ranking information for SearchJobsRequest. — shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
  --disable-keyword-match: oneof<nothing, bool> # Optional. Controls whether to disable exact keyword match on Job.job_title, Job.description, Job.company_display_name, Job.locations, Job.qualifications. When disable keyword match is turned off, a keyword match returns jobs that do not match given category filters when there are matching keywords. For example, the query "program manager," a result is returned even if the job posting has the title "software developer," which does not fall into "program manager" ontology, but does have "program manager" appearing in its description. For queries like "cloud" that does not contain title or location specific ontology, jobs with "cloud" keyword matches are returned regardless of this flag's value. Please use Company.keyword_searchable_custom_fields or Company.keyword_searchable_custom_attributes if company specific globally matched custom field/attribute string values is needed. Enabling keyword match improves recall of subsequent search requests. Defaults to false.
  --diversification-level: string@diversification-level-completer # Optional. Controls whether highly similar jobs are returned next to each other in the search results. Jobs are identified as highly similar based on their titles, job categories, and locations. Highly similar results are clustered so that only one representative job of the cluster is displayed to the job seeker higher up in the results, with the other jobs being displayed lower down in the results. Defaults to DiversificationLevel.SIMPLE if no value is specified.
  --enable-broadening: oneof<nothing, bool> # Optional. Controls whether to broaden the search when it produces sparse results. Broadened queries append results to the end of the matching results list. Defaults to false.
  --histogram-facets: record # Input only. Histogram facets to be specified in SearchJobsRequest. — shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
  --histogram-queries: list # Optional. Expression based histogram requests for jobs matching JobQuery. — item shape: {histogramQuery?: string}
  --job-query: record # Input only. The query required to perform a search query. — shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.SMALL if no value is specified.
  --offset: int # Optional. An integer that specifies the current offset (that is, starting result location, amongst the jobs deemed by the API as relevant) in search results. This field is only considered if page_token is unset. The maximum allowed value is 5000. Otherwise an error is thrown. For example, 0 means to return results starting from the first matching job, and 10 means to return from the 11th job. This can be used for pagination, (for example, pageSize = 10 and offset = 10 means to return from the second page). (format: int32)
  --order-by: string # Optional. The criteria determining how search results are sorted. Default is "relevance desc". Supported options are: * `"relevance desc"`: By relevance descending, as determined by the API algorithms. Relevance thresholding of query results is only available with this ordering. * `"posting_publish_time desc"`: By Job.posting_publish_time descending. * `"posting_update_time desc"`: By Job.posting_update_time descending. * `"title"`: By Job.title ascending. * `"title desc"`: By Job.title descending. * `"annualized_base_compensation"`: By job's CompensationInfo.annualized_base_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_base_compensation desc"`: By job's CompensationInfo.annualized_base_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation"`: By job's CompensationInfo.annualized_total_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation desc"`: By job's CompensationInfo.annualized_total_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"custom_ranking desc"`: By the relevance score adjusted to the SearchJobsRequest.custom_ranking_info.ranking_expression with weight factor assigned by SearchJobsRequest.custom_ranking_info.importance_level in descending order. * Location sorting: Use the special syntax to order jobs by distance: "`distance_from('Hawaii')`": Order by distance from Hawaii. "`distance_from(19.89, 155.5)`": Order by distance from a coordinate. "`distance_from('Hawaii'), distance_from('Puerto Rico')`": Order by multiple locations. See details below. "`distance_from('Hawaii'), distance_from(19.89, 155.5)`": Order by multiple locations. See details below. The string can have a maximum of 256 characters. When multiple distance centers are provided, a job that is close to any of the distance centers would have a high rank. When a job has multiple locations, the job location closest to one of the distance centers will be used. Jobs that don't have locations will be ranked at the bottom. Distance is calculated with a precision of 11.3 meters (37.4 feet). Diversification strategy is still applied unless explicitly disabled in diversification_level.
  --page-size: int # Optional. A limit on the number of jobs returned in the search results. Increasing this value above the default value of 10 can increase search response time. The value can be between 1 and 100. (format: int32)
  --page-token: string # Optional. The token specifying the current offset within search results. See SearchJobsResponse.next_page_token for an explanation of how to obtain the next set of query results.
  --request-metadata: record # Input only. Meta information related to the job searcher or entity conducting the job search. This information is used to improve the performance of the service. — shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
  --require-precise-result-size: oneof<nothing, bool> # This field is deprecated.
  --search-mode: string@search-mode-completer # Optional. Mode of a search. Defaults to SearchMode.JOB_SEARCH.
]: any -> oneof<record, string, nothing> {
  $in | http-request {
    method: post
    path: "/v3p1beta1/{parent}/jobs:searchForAlert"
    path_params: [{name: parent, var: parent}]
    query: [{name: "$.xgafv", var: xgafv}, {name: access_token, var: access_token}, {name: alt, var: alt}, {name: callback, var: callback}, {name: fields, var: fields}, {name: key, var: key}, {name: oauth_token, var: oauth_token}, {name: prettyPrint, var: pretty_print}, {name: quotaUser, var: quota_user}, {name: upload_protocol, var: upload_protocol}, {name: uploadType, var: upload_type}]
    body: {content_type: "application/json", kind: json, fields: [{name: customRankingInfo, var: custom_ranking_info}, {name: disableKeywordMatch, var: disable_keyword_match}, {name: diversificationLevel, var: diversification_level}, {name: enableBroadening, var: enable_broadening}, {name: histogramFacets, var: histogram_facets}, {name: histogramQueries, var: histogram_queries}, {name: jobQuery, var: job_query}, {name: jobView, var: job_view}, {name: offset, var: offset}, {name: orderBy, var: order_by}, {name: pageSize, var: page_size}, {name: pageToken, var: page_token}, {name: requestMetadata, var: request_metadata}, {name: requirePreciseResultSize, var: require_precise_result_size}, {name: searchMode, var: search_mode}]}
    accept: ["application/json"]
    ok: [200]
    auth: bearer
  } {
    parent: $parent, xgafv: $xgafv, access_token: $access_token, alt: $alt, callback: $callback, fields: $fields, key: $key, oauth_token: $oauth_token, pretty_print: $pretty_print, quota_user: $quota_user, upload_protocol: $upload_protocol, upload_type: $upload_type, custom_ranking_info: $custom_ranking_info, disable_keyword_match: $disable_keyword_match, diversification_level: $diversification_level, enable_broadening: $enable_broadening, histogram_facets: $histogram_facets, histogram_queries: $histogram_queries, job_query: $job_query, job_view: $job_view, offset: $offset, order_by: $order_by, page_size: $page_size, page_token: $page_token, request_metadata: $request_metadata, require_precise_result_size: $require_precise_result_size, search_mode: $search_mode
    base_url: $base_url, token: $token, auth_scheme: $auth_scheme, insecure: $insecure, max_time: $max_time, raw: $raw, allow_errors: $allow_errors, full: $full, dry_run: $dry_run
  }
}
